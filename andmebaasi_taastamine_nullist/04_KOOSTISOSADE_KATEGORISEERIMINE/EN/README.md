# Ingredient categorization and fact_ingredients creation

**Liina wrote the original categorization code and fact_ingredients table-creation code.** This revision aligns table references and documentation and adds supplementary restoration and validation scripts.

Stage: **CAT_STEP_00–CAT_STEP_03** · Updated: **2026-10-05** · Estonian version: `../README.md`.

## 1. Purpose and position in reconstruction

This module belongs in `andmebaasi_taastamine_nullist/04_KOOSTISOSADE_KATEGORISEERIMINE`. Python reads previously extracted ingredients and the reference table directly from PostgreSQL, finds exact text matches and populates the BI fact. It does not read CSV directly; import the CSV into PostgreSQL first.

The previous ingredient extraction or CSV restoration stage must have created `vet_analytics.product_ingredients_rows`. Nutrient normalization and `vet_clean_bi` creation have separate instructions. Categorization does not read `vet_clean_bi`.

| Role | Table | Required columns |
|---|---|---|
| Input | `vet_analytics.product_ingredients_rows` | `_id`, `ingredient`; other columns may remain |
| Reference | `vet_analytics.ingredients_categories_reference` | All seven CSV headers |
| BI output | `vet_powerbi.fact_ingredients` | `product_id`, `ingredient`, `category`, `protein`, `oil`, `carbs` |

The source retains `_id`; Python copies its value into output `product_id`. The workflow no longer creates `vet_analytics.fact_ingredients`. It does not move or delete historical tables.

## 2. Files and execution order

| Step | File / action | Result |
|---|---|---|
| `CAT_STEP_00` | `00_create_reference_table.sql`, then CSV import | Seven-column reference table with data |
| `CAT_STEP_01` | `fact_ingredients_loomine.sql` | Six-column fact in `vet_powerbi` |
| `CAT_STEP_02` | `kategoriseerimine2.py` | Committed categorized fact rows |
| `CAT_STEP_03` | `03_validation.sql` | Counts, keys, duplicate and category review |

Supporting files: `categories_reference.csv`, `requirements.txt`, `.env.example`, `.gitignore`, `CHANGELOG.md` and `EXECUTION_LOG.md`. The Estonian and English folders are equivalent alternatives: run only one language version. `../../99_ARHIIV_EI_KAIVITA/algne_pakett_20261005.zip` preserves all four supplied files for comparison; these are not additional execution steps.

## 3. Restoring the reference in DBeaver

1. Connect to the database containing `vet_analytics.product_ingredients_rows`.
2. Execute the complete `00_create_reference_table.sql`. It creates a missing schema/table and adds `Human Review` and `Review Reason` to an older five-column reference table.
3. Select the reference table → **Import Data** → CSV and choose this folder's `categories_reference.csv`.
4. Use UTF-8 encoding, delimiter **`;`**, the first row as headers and quote character `"`. Map values by exact column names; blank fields may become NULL.
5. Verify all seven headers: `Ingredient`, `Category`, `Human Review`, `Review Reason`, `Protein`, `Oil`, `Carbs`. All columns are TEXT.
6. Import into an empty table for initial reconstruction. Do not append the same rows on reimport. When replacing the entire reference with this CSV, use DBeaver's option to clear the target during import after backing up existing content. Manual additions are not included in the supplied CSV.

The supplied CSV has **6759 rows**, including **2193** without a category and **690** with `+` in the category. **18** normalized ingredient keys are repeated; their usable category/protein/oil/carbs mappings have no conflicts. The imported snapshot should contain 6759 rows. Record actual counts after later additions.

The CSV is byte-identical in both language folders. Do not translate data values or headers: they are matching inputs and part of the database contract.

## 4. Creating the fact

Execute the complete `fact_ingredients_loomine.sql` in DBeaver. It creates `vet_powerbi` and the empty six-column fact only when absent. Existing fact rows are preserved. The check block requires an existing table to contain all six columns.

If an old table still uses `_id`, validation stops. Follow the project's existing column-renaming step and inspect BI dependencies; this script performs no implicit migration. The current contract is `product_id`.

Product IDs are not unique in this fact: a product can have several ingredients. The script adds no primary key and changes no existing BI keys, indexes or grants.

## 5. Python connection and dependencies

Use the same PostgreSQL server and database in VS Code and DBeaver. The following PowerShell commands create an environment and install dependencies; use a suitable existing environment when available.

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Run these commands inside the selected language folder. `pandas` processes tables, `SQLAlchemy` manages the connection, `psycopg2-binary` is the PostgreSQL driver and `python-dotenv` loads settings. No additional CSV/Excel-reading dependency is needed. Record the versions used successfully.

Copy `.env.example` next to the script as `.env` and replace the password placeholder:

```dotenv
DB_HOST=localhost
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD="your_actual_password"
```

This format matches the ingredient extraction module. `URL.create()` handles password special characters. The previous `DATABASE_URL` format is also supported. When set, it takes precedence over DB_* settings. Existing environment variables take precedence over `.env`. A `DATABASE_URL` driver must match the installed library; this package installs `postgresql+psycopg2`. Password special characters in a URL must be URL-encoded.

Do not include `.env` in GitHub or a shared package. The supplied `.gitignore` excludes it. Install dependencies into the Python environment used to run the script.

## 6. Running categorization

1. Confirm that the reference has been imported and `CAT_STEP_01` is complete.
2. Run the command below. Change the final sequence number for reruns to preserve previous logs.
3. Check for the `OUTPUT COMMITTED` message. A matching summary alone does not prove successful storage.
4. Refresh tables in DBeaver, run `03_validation.sql` and complete `EXECUTION_LOG.md`.

```powershell
.\.venv\Scripts\python.exe kategoriseerimine2.py 2>&1 | Tee-Object CAT_STEP_02_run_20261005_01.txt
```

Python checks the three tables and required columns before reading. If no usable output is produced, it stops before clearing the target.

A successful run **replaces all contents of `vet_powerbi.fact_ingredients`**. `TRUNCATE` and `append` occur within one `engine.begin()` transaction. A write error rolls back changes. The table is not recreated, preserving existing indexes and grants. Foreign keys, mandatory extra columns, missing privileges or incompatible types can block writing; the script uses no CASCADE. Avoid concurrent updates to the same fact.

## 7. Preserved matching rules

- Matching removes invisible/control characters, uses lowercase and normalizes whitespace. Original `ingredient` text is preserved in output.
- Matching is exact after cleaning; no partial matches, new translations or inferred categories are added.
- Empty ingredients and input rows without a usable match/category are excluded. `Not found in reference` includes ingredients present in the reference without a category, because those reference entries are omitted from the lookup.
- Only the first `+`-separated category is used. For example, `animal protein + oil` becomes `animal protein`.
- `protein`, `oil` and `carbs` are copied from the reference. `Yes`, `No` and `Review` are not converted into boolean flags.
- `Human Review` and `Review Reason` remain in the reference; they are neither copied to the six-column fact nor used to change existing matching behavior. A row requiring human review can therefore receive a fact category.
- Each matched input row produces one output row. Input duplicates are not removed. Repeated normalized reference keys are accepted only when their usable category/protein/oil/carbs values agree; conflicts stop before writing the fact. Usable duplicates in the supplied CSV have identical mapping values. Resolve any future conflicts before execution.

An unmatched or excluded ingredient does not prove its absence from the food. This limitation matters when interpreting allergen filters.

## 8. BI dependencies and validation

After successful categorization, run stage 05 model creation, dimension enrichment and validation. For an existing model, use 05/003 enrichment, 05/004 checks and stage 07 acceptance, then refresh Power BI. Categorization itself does not update the dimension.

During reconstruction, categorize the fact before the final population of its dependent dimension. A later script that resets the BI schema may delete the fact; if so, recreate and populate it again. Product relationships use the fact's `product_id` and the existing product dimension.

Validation error counters and unknown product–ingredient pairs should be zero. Review duplicates; ingredient row counts need not match product or input row counts. Compare the console output count with the stored count.

## 9. Logs and review scope

No connection to your PostgreSQL database or real-table write occurred here. All database steps are **NOT_RUN**.