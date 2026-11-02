# SCRIPT: kategoriseerimine2.py
# STEP ID: CAT_STEP_02
# PURPOSE: Koostisosade kategoriseerimine
# INPUT: vet_analytics.product_ingredients_rows; vet_analytics.ingredients_categories_reference
# OUTPUT: vet_powerbi.fact_ingredients
# PREREQUISITES: README.md
# VALIDATION: 03_validation.sql
# EXECUTION LOG: EXECUTION_LOG.md
# EXECUTION STATUS: NOT_RUN
# ORIGINAL WORK: Algse koodi koostas Liina; ühtlustamine 05.10.2026
# REVISION: 2026-10-05
# SOURCE POLICY: Sisendtabelid säilivad
# RUN POLICY: README.md

import os
import re

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import URL


# ============================================================
# 1. ANDMEBAASIÜHENDUS
# ============================================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

load_dotenv(os.path.join(BASE_DIR, ".env"))

# Loe skripti kõrval olevad ühendusseaded nagu eraldamise etapis.
database_url = os.getenv("DATABASE_URL")

if not database_url:
    required_settings = ("DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD")
    missing_settings = [name for name in required_settings if not os.getenv(name)]
    if missing_settings:
        raise RuntimeError(
            "Määra .env failis DATABASE_URL või kõik DB_* seaded. Puuduvad: "
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

# Kontrolli nõutud veerge enne lugemist või sihttabeli tühjendamist.
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
        raise RuntimeError(f"Nõutud tabel puudub: {schema_name}.{table_name}")
    actual_columns = {
        column["name"]
        for column in inspector.get_columns(table_name, schema=schema_name)
    }
    missing_columns = set(required_columns) - actual_columns
    if missing_columns:
        raise RuntimeError(
            f"Puuduvad veerud tabelis {schema_name}.{table_name}: "
            + ", ".join(sorted(missing_columns))
        )


# ============================================================
# 2. TOODETE KOOSTISOSADE LUGEMINE POSTGRESQL-IST
# ============================================================

print("Loen toodete koostisosi PostgreSQL-ist...")

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
    f"Sisendridu: {len(input_df):,}"
)


# ============================================================
# 3. VÕRDLUSTABELI LUGEMINE POSTGRESQL-IST
# ============================================================

print("Loen koostisosade võrdlustabelit PostgreSQL-ist...")

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
    f"Võrdlustabeli ridu: {len(reference_df):,}"
)


# ============================================================
# 4. TEKSTI PUHASTAMINE SOBITAMISEKS
# ============================================================

def clean_text(value):
    """
    Puhasta teksti ainult sobitamiseks.

    Algne koostisosatekst säilib
    väljundtabelis.
    """

    if pd.isna(value):
        return ""

    value = str(value)

    # Eemalda nähtamatud ja juhtmärgid
    value = "".join(
        character
        for character in value
        if character.isprintable()
    )

    # Muuda väiketähtedeks
    value = value.lower()

    # Ühtlusta tühikud
    value = re.sub(
        r"\s+",
        " ",
        value
    )

    return value.strip()


# ============================================================
# 5. VÕRDLUSTABELI ETTEVALMISTAMINE
# ============================================================

reference_df["_ingredient_clean"] = (
    reference_df["Ingredient"]
    .apply(clean_text)
)


# ============================================================
# 6. SOBITUSSÕNASTIKU LOOMINE
# ============================================================

reference_lookup = {}

for _, row in reference_df.iterrows():

    ingredient = row["_ingredient_clean"]

    category = row["Category"]

    # Jäta tühi koostisosa vahele
    if not ingredient:
        continue

    # Jäta puuduv kategooria vahele
    if pd.isna(category):
        continue

    category = str(category).strip()

    # Jäta tühi kategooria vahele
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
    f"Kasutatavaid võrdlusvasteid: "
    f"{len(reference_lookup):,}"
)


# ============================================================
# 7. KOOSTISOSADE SOBITAMINE VÕRDLUSTABELIGA
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
    # Tühi koostisosa
    # --------------------------------------------------------

    if not clean_ingredient:

        skipped_empty += 1

        continue


    # --------------------------------------------------------
    # Otsi täpset puhastatud tekstivastet
    # --------------------------------------------------------

    reference = reference_lookup.get(
        clean_ingredient
    )


    # --------------------------------------------------------
    # Koostisosa ei leitud
    # --------------------------------------------------------

    if reference is None:

        skipped_not_found += 1

        continue


    category_string = reference["category"]


    # --------------------------------------------------------
    # Kategooria puudub
    # --------------------------------------------------------

    if not category_string:

        skipped_no_category += 1

        continue


    # --------------------------------------------------------
    # Kui mitu kategooriat on eraldatud märgiga "+",
    # kasuta ainult esimest kategooriat.
    #
    # Näide:
    #
    # "animal protein + oil"
    #
    # tulemuseks on:
    #
    # "animal protein"
    # --------------------------------------------------------

    category = category_string.split("+")[0].strip()


    # --------------------------------------------------------
    # Kategooria on pärast töötlemist tühi
    # --------------------------------------------------------

    if not category:

        skipped_no_category += 1

        continue


    matched_input_rows += 1


    # --------------------------------------------------------
    # Loo iga sobitatud sisendkoostisosa jaoks üks väljundrida
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
# 8. TULEMUSE ANDMERAAMI LOOMINE
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
# 9. KOKKUVÕTTE VÄLJASTAMINE
# ============================================================

print()
print("=" * 60)
print("KATEGORISEERIMINE LÕPETATUD")
print("=" * 60)

print(
    f"Sisendridu:              {len(input_df):,}"
)

print(
    f"Sobitatud sisendridu:      {matched_input_rows:,}"
)

print(
    f"Väljundridu:    {len(result_df):,}"
)

print(
    f"Tühi koostisosas:       {skipped_empty:,}"
)

print(
    f"Võrdlustabelist leidmata:  {skipped_not_found:,}"
)

print(
    f"Kategooriata:             {skipped_no_category:,}"
)


# ============================================================
# 10. TULEMUSE KIRJUTAMINE POSTGRESQL-I
# ============================================================

print()
# Katkesta enne TRUNCATE käsku, kui kasutatavaid vasteid ei tekkinud.
if result_df.empty:
    raise RuntimeError(
        "Kategoriseeritud ridu ei tekkinud. Olemasolevat sihttabelit ei muudetud."
    )

print("Kirjutan tulemust PostgreSQL-i...")


with engine.begin() as connection:

    # Tühjenda varasem genereeritud tulemus
    connection.execute(
        text(
            """
            TRUNCATE TABLE
            vet_powerbi.fact_ingredients
            """
        )
    )

    # Lisa uus tulemus
    result_df.to_sql(
        "fact_ingredients",
        connection,
        schema="vet_powerbi",
        if_exists="append",
        index=False
    )


print()
print("OUTPUT COMMITTED. Tulemus salvestatud tabelisse:")

print(
    "vet_powerbi.fact_ingredients"
)


