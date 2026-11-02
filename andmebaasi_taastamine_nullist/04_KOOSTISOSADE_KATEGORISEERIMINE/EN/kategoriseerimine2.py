# SCRIPT: kategoriseerimine2.py
# STEP ID: CAT_STEP_02
# PURPOSE: Categorize ingredients
# INPUT: vet_analytics.product_ingredients_rows; vet_analytics.ingredients_categories_reference
# OUTPUT: vet_powerbi.fact_ingredients
# PREREQUISITES: README.md
# VALIDATION: 03_validation.sql
# EXECUTION LOG: EXECUTION_LOG.md
# EXECUTION STATUS: NOT_RUN
# ORIGINAL WORK: Original code by Liina; compatibility revision 2026-10-05
# REVISION: 2026-10-05
# SOURCE POLICY: Source tables are preserved
# RUN POLICY: README.md

import os
import re

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import URL


# ============================================================
# 1. DATABASE CONNECTION
# ============================================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

load_dotenv(os.path.join(BASE_DIR, ".env"))

# Load the same script-local settings as the extraction stage.
database_url = os.getenv("DATABASE_URL")

if not database_url:
    required_settings = ("DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD")
    missing_settings = [name for name in required_settings if not os.getenv(name)]
    if missing_settings:
        raise RuntimeError(
            "Set DATABASE_URL or all DB_* settings in .env. Missing: "
            + ", ".join(missing_settings)
        )
    database_url = URL.create(
        "postgresql+psycopg2",
        username=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        host=os.getenv("DB_HOST"),
        port=int(os.getenv("DB_PORT")),
        database=os.getenv("DB_NAME")
    )

engine = create_engine(database_url)

# Validate all required columns before reading or clearing the target.
required_tables = {
    ("vet_analytics", "product_ingredients_rows"): ["_id", "ingredient"],
    ("vet_analytics", "ingredients_categories_reference"): [
        "Ingredient", "Category", "Protein", "Oil", "Carbs"
    ],
    ("vet_powerbi", "fact_ingredients"): [
        "product_id", "ingredient", "category", "protein", "oil", "carbs"
    ]
}
inspector = inspect(engine)
for (schema_name, table_name), required_columns in required_tables.items():
    if not inspector.has_table(table_name, schema=schema_name):
        raise RuntimeError(f"Required table is missing: {schema_name}.{table_name}")
    actual_columns = {
        column["name"]
        for column in inspector.get_columns(table_name, schema=schema_name)
    }
    missing_columns = set(required_columns) - actual_columns
    if missing_columns:
        raise RuntimeError(
            f"Missing columns in {schema_name}.{table_name}: "
            + ", ".join(sorted(missing_columns))
        )


# ============================================================
# 2. READ PRODUCT INGREDIENTS FROM POSTGRESQL
# ============================================================

print("Reading product ingredients from PostgreSQL...")

input_df = pd.read_sql(
    """
    SELECT
        "_id",
        "ingredient"
    FROM vet_analytics.product_ingredients_rows
    """,
    engine
)

print(
    f"Input rows: {len(input_df):,}"
)


# ============================================================
# 3. READ REFERENCE TABLE FROM POSTGRESQL
# ============================================================

print("Reading ingredient reference table from PostgreSQL...")

reference_df = pd.read_sql(
    """
    SELECT
        "Ingredient",
        "Category",
        "Protein",
        "Oil",
        "Carbs"
    FROM vet_analytics.ingredients_categories_reference
    """,
    engine
)

print(
    f"Reference rows: {len(reference_df):,}"
)


# ============================================================
# 4. CLEAN TEXT FOR MATCHING
# ============================================================

def clean_text(value):
    """
    Clean text only for matching.

    The original ingredient text is preserved
    in the output database.
    """

    if pd.isna(value):
        return ""

    value = str(value)

    # Remove invisible/control characters
    value = "".join(
        character
        for character in value
        if character.isprintable()
    )

    # Lowercase
    value = value.lower()

    # Normalize whitespace
    value = re.sub(
        r"\s+",
        " ",
        value
    )

    return value.strip()


# ============================================================
# 5. PREPARE REFERENCE TABLE
# ============================================================

reference_df["_ingredient_clean"] = (
    reference_df["Ingredient"]
    .apply(clean_text)
)


# ============================================================
# 6. CREATE REFERENCE LOOKUP
# ============================================================

reference_lookup = {}

for _, row in reference_df.iterrows():

    ingredient = row["_ingredient_clean"]

    category = row["Category"]

    # Ignore empty ingredient
    if not ingredient:
        continue

    # Ignore missing category
    if pd.isna(category):
        continue

    category = str(category).strip()

    # Ignore empty category
    if not category:
        continue

    existing = reference_lookup.get(ingredient)
    candidate = {
        "category": category,
        "protein": row["Protein"],
        "oil": row["Oil"],
        "carbs": row["Carbs"]
    }
    if existing is not None:
        normalized = lambda data: tuple(
            None if pd.isna(data[key]) else str(data[key]).strip()
            for key in ("category", "protein", "oil", "carbs")
        )
        if normalized(existing) != normalized(candidate):
            raise RuntimeError(
                f"Conflicting reference rows for ingredient: {ingredient}. "
                "Resolve the reference before writing fact_ingredients."
            )

    reference_lookup[ingredient] = {
        "category": category,
        "protein": row["Protein"],
        "oil": row["Oil"],
        "carbs": row["Carbs"]
    }


print(
    f"Usable reference mappings: "
    f"{len(reference_lookup):,}"
)


# ============================================================
# 7. MATCH INPUT INGREDIENTS TO REFERENCE TABLE
# ============================================================

result_rows = []

skipped_empty = 0
skipped_not_found = 0
skipped_no_category = 0
matched_input_rows = 0


for _, input_row in input_df.iterrows():

    source_id = input_row["_id"]

    original_ingredient = input_row["ingredient"]

    clean_ingredient = clean_text(
        original_ingredient
    )


    # --------------------------------------------------------
    # Empty ingredient
    # --------------------------------------------------------

    if not clean_ingredient:

        skipped_empty += 1

        continue


    # --------------------------------------------------------
    # Look for exact normalized match
    # --------------------------------------------------------

    reference = reference_lookup.get(
        clean_ingredient
    )


    # --------------------------------------------------------
    # Ingredient NOT found
    # --------------------------------------------------------

    if reference is None:

        skipped_not_found += 1

        continue


    category_string = reference["category"]


    # --------------------------------------------------------
    # Category missing
    # --------------------------------------------------------

    if not category_string:

        skipped_no_category += 1

        continue


    # --------------------------------------------------------
    # If multiple categories are separated by "+",
    # use ONLY the first category.
    #
    # Example:
    #
    # "animal protein + oil"
    #
    # becomes:
    #
    # "animal protein"
    # --------------------------------------------------------

    category = category_string.split("+")[0].strip()


    # --------------------------------------------------------
    # Category empty after processing
    # --------------------------------------------------------

    if not category:

        skipped_no_category += 1

        continue


    matched_input_rows += 1


    # --------------------------------------------------------
    # Create ONE output row per ingredient
    # --------------------------------------------------------

    result_rows.append({
        "product_id": source_id,
        "ingredient": original_ingredient,
        "category": category,
        "protein": reference["protein"],
        "oil": reference["oil"],
        "carbs": reference["carbs"]
    })


# ============================================================
# 8. CREATE RESULT DATAFRAME
# ============================================================

result_df = pd.DataFrame(
    result_rows,
    columns=[
        "product_id",
        "ingredient",
        "category",
        "protein",
        "oil",
        "carbs"
    ]
)


# ============================================================
# 9. PRINT SUMMARY
# ============================================================

print()
print("=" * 60)
print("CATEGORIZATION FINISHED")
print("=" * 60)

print(
    f"Input rows:              {len(input_df):,}"
)

print(
    f"Matched input rows:      {matched_input_rows:,}"
)

print(
    f"Output database rows:    {len(result_df):,}"
)

print(
    f"Empty ingredients:       {skipped_empty:,}"
)

print(
    f"Not found in reference:  {skipped_not_found:,}"
)

print(
    f"No category:             {skipped_no_category:,}"
)


# ============================================================
# 10. WRITE RESULTS TO POSTGRESQL
# ============================================================

print()
# Stop before TRUNCATE if the input/reference produced no usable matches.
if result_df.empty:
    raise RuntimeError(
        "No categorized rows were produced. The existing target was not changed."
    )

print("Writing results to PostgreSQL...")


with engine.begin() as connection:

    # Clear previous generated results
    connection.execute(
        text(
            """
            TRUNCATE TABLE
            vet_powerbi.fact_ingredients
            """
        )
    )

    # Insert new results
    result_df.to_sql(
        "fact_ingredients",
        connection,
        schema="vet_powerbi",
        if_exists="append",
        index=False
    )


print()
print("OUTPUT COMMITTED. Results written to:")

print(
    "vet_powerbi.fact_ingredients"
)

