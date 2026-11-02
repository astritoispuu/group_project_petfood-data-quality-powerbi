# Extract ingredient rows from PostgreSQL with Python

Step: **AST-ING** · Updated: **2026-10-05** · [Eesti](README.md)

**Original code, extraction rules, and original README by Astrit.** This update aligns schema references, documentation style, logging, and the English copy. Astrit's extraction rules are retained.

## 1. Purpose and restoration sequence

`product_extract.py` reads product descriptions from PostgreSQL, cleans their text, and creates one row per extracted ingredient. Python and DBeaver connect independently to the same PostgreSQL database. DBeaver is used to inspect the database and run SQL.

Place the full module at `andmebaasi_taastamine_nullist/03_KOOSTISOSADE_ERALDAMINE`. The English copy is in its `EN` subfolder.

| Order | Step | Result / dependency |
|---|---|---|
| 1 | Import and clean product data | `vet_analytics.vet_clean` |
| 2 | Create conversion functions, normalize nutrients, validate | `vet_analytics.vet_clean_mg_kg` |
| 3 | Run this Python script and validate output | `vet_analytics.product_ingredients_rows` |
| 4 | Restore the ingredient reference table and categorize | Required inputs for the later categorization script |
| 5 | Follow the separate categorization and BI instructions | `vet_powerbi.fact_ingredients` and `vet_powerbi.dim_ingredients` |

Create `vet_clean_bi` according to its separate instructions before building the BI model. Ingredient extraction does not require `vet_clean_bi`. Follow the wider package's BI/categorization order because categorization may require an existing `vet_powerbi` schema. This module does not implement those steps.

## 2. Tables and columns

| Role | Schema and table | Columns |
|---|---|---|
| Input | `vet_analytics.vet_clean_mg_kg` | `_id`, `product_name_fi`, `product_name_en`, `product_content` |
| Output | `vet_analytics.product_ingredients_rows` | `_id`, `product_name_fi`, `product_name_en`, `ingredient` |
| Later BI fact | `vet_powerbi.fact_ingredients` | `product_id`, `ingredient`, `category`, `protein`, `oil`, `carbs`, as documented separately |

**Keep `_id` in this intermediate table.** The downstream categorization step uses it; the BI fact uses `product_id`. This script does not create/update BI tables or assign categories.

The latest inspected normalization script selects `v.*`, retaining the required source columns. Python checks these columns before reading. The outdated `vet_clean_gea_20260928` reference in the original guide has been replaced with the actual source table.

## 3. Files

| File | Purpose |
|---|---|
| `product_extract.py` | Extraction; English comments and console messages |
| `README.md`, `README_EN.md` | Equivalent Estonian and English instructions |
| `.env.example` | Template for each user's connection settings |
| `.gitignore` | Excludes `.env`, the virtual environment, and Python cache |
| `requirements.txt` | Four dependencies used by this script |
| `003_preflight.sql` | Source table, column, and product key checks |
| `004_validation.sql` | Persisted output checks |

Dated change logs and execution-log templates belong in `00_JUHEND_JA_LOGI`. Keep existing `001_loo_importtabelid.sql` and `002_kontrolli_sisendeid.sql` for the CSV-import route.

## 4. Two restoration routes

**A. Re-run extraction.** Restore `vet_clean_mg_kg`, run Python, and validate the output. Python creates the output table; no manual table creation is required. Restore the reference table using its own import instructions.

**B. Restore the existing export.** Import `product_ingredients_rows.csv` using the previous import guide. Do not run extraction for this route. The new validation queries can also check imported data.

Choose one route. Running Python after importing the CSV replaces that intermediate table. Historical manual corrections in an export may not be reproduced by extraction. The attached CSV is a checked snapshot, not this script's input: the script reads neither CSV nor Excel files.

## 5. Connection and dependencies

Open the restoration package's root folder in VS Code. Inspect the PostgreSQL host, port, database, and username in DBeaver's connection settings. Python must use the same server and database.

These PowerShell commands create a virtual environment and install dependencies. Use an existing suitable environment if available.

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r "03_KOOSTISOSADE_ERALDAMINE/requirements.txt"
```

Dependencies: `pandas` for processing, `SQLAlchemy` for connection and table writes, `psycopg2-binary` for the PostgreSQL driver, and `python-dotenv` for settings. This script does not require `openpyxl`; downstream scripts reading Excel may require it. Versions are not locked; record versions used for a successful run.

Copy `03_KOOSTISOSADE_ERALDAMINE/.env.example` beside the script as `.env`. Replace the placeholder values with your own connection settings.

```dotenv
DB_HOST=localhost
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD="your_actual_password"
```

Use `localhost` only for PostgreSQL running on your computer; use the actual host for a remote server. Do not append comments inside values such as `postgres###your_database`. This script expects the five `DB_*` settings and does not read `DATABASE_URL`. The `.env` path is relative to the script, independent of the terminal directory. Existing environment variables take precedence over `.env`. `URL.create()` handles password special characters without manually constructing a URL.

Keep the real `.env` local; the package includes only a template. Also exclude `.env` and the root `.venv/` in the repository root's `.gitignore`.

## 6. Run the step

1. Restore `vet_analytics.vet_clean_mg_kg` and validate normalization.
2. Run `003_preflight.sql` in DBeaver. The source must exist and include all four required columns. Review missing or duplicate product IDs before proceeding.
3. Configure `.env` and install dependencies.
4. Run Python from the package root using the command below.
5. Check for `OUTPUT COMMITTED` and the final summary. `Written in transaction` reports an uncommitted batch.
6. Refresh `vet_analytics` → `Tables` in DBeaver.
7. Run `004_validation.sql`, inspect results, and complete the execution log.
8. Continue with the reference, categorization, and BI instructions. Rebuild dependent results whenever extraction is re-run.

This PowerShell command runs extraction and saves console output. Change the log filename for each subsequent run to preserve previous evidence.

```powershell
.\.venv\Scripts\python.exe "03_KOOSTISOSADE_ERALDAMINE/product_extract.py" 2>&1 | Tee-Object "00_JUHEND_JA_LOGI/AST_ING_EN_run_20261005_01.txt"
```

A console log alone does not prove success. An error or missing `OUTPUT COMMITTED` means the step must not be recorded as successful.

## 7. Writes and repeat runs

Astrit's existing write logic is retained. Data is processed in memory and written in 500-row batches to `vet_analytics.product_ingredients_rows_tmp`. This is a regular schema table used for staging, not a PostgreSQL `TEMP TABLE`. After all batches succeed, the old output is dropped and the staging table renamed to `product_ingredients_rows`. Writes and the rename share one transaction; any failure rolls it back and preserves previous output.

Empty extraction now raises an error before writing. An old output table must not be treated as a fresh result.

Successful replacement recreates the table; indexes, constraints, and table-specific grants are not automatically retained. A dependent view or foreign key may block the drop; there is no `CASCADE`. Do not run ET and EN copies concurrently because they use the same staging-table name.

## 8. Extraction rules

Astrit's extraction rules are retained. Text is lowercased, known spelling issues are corrected, configured phrases and words are removed, and text is split into ingredients. Removal lists are deduplicated and ordered with longer patterns first. Duplicates are removed within one source product row; source product IDs must be unique.

| Setting / function | Behavior |
|---|---|
| `PARENTHESES_MODE = "join"` | Default: `rasv (kana)` → `rasv kana` |
| `"extract"` | Separate parenthesized content: `rasv (kana)` → `rasv` and `kana` |
| `"remove"` | Discard parenthesized content |
| `KEEP_E_NUMBERS = True` | Protect E-numbers such as `e322` |
| Protected omega terms | Restore `omega-3`, `omega-6`, `omega-9` and supported spelling variants after splitting |
| Repeated adjacent words | For example, `beef beef` → `beef` |

Ordinary digits are removed. Protected omega terms and E-numbers are restored after digit checks, so valid output can contain digits. Fragments longer than four words and values without letters or below the minimum length are excluded. English, Finnish, and Swedish ingredient names are not translated to one language.

Example: `Chicken (40%), rice, fish oil, vitamins` → `chicken`, `rice`, `fish oil`. Parenthesis examples describe only that processing step; other cleaning rules can further alter the result.

`STATS["raw_splits"]` counts cleaned candidates before deduplication. `STATS["removed_duplicates"]` counts removed duplicates. Documentation now uses the actual `seen` and `STATS` names instead of the original guide's `seen_ingredients` and `TOTAL_*` names.

Rules can leave marketing text or remove actual ingredients. Check sample output against original `product_content`. Absence of an extracted ingredient does not establish its absence from food. Record future rule changes and rerun extraction and dependent steps.

## 9. Validation and logging

`004_validation.sql` checks output counts, columns, unknown product IDs, blank values, and duplicate pairs. Unknown-ID and duplicate queries should return no rows; blank ID and ingredient counts should be zero. Ingredient rows need not equal product rows.

Local attached-CSV check: **86,264** rows, **8,644** distinct product IDs, **0** duplicate product–ingredient pairs, and **0** blank ingredient names. These describe the CSV, not the current live database.

Python syntax, extraction-rule equivalence, and sample cases including all three parenthesis modes and protected omega/E-number terms were checked locally. The older package's 15,202 source rows produced exactly the same 86,264 product–ingredient pairs as the attached CSV; product names and row order were not compared. Success, second-batch failure, rename failure, and empty output were checked with test substitutes. Details are recorded in the change log. No connection to your PostgreSQL server or live write was performed. Record actual execution only after completing it.

Log timestamp, operator, database, file, input/output counts, status, and exceptions. Change history: `../00_JUHEND_JA_LOGI/varasemad_logid/CHANGELOG_ASTRIT_INGREDIENTS_20261005_EN.md`.

## 10. Language copies and authorship

There is one shared Astrit algorithm in this folder. `EN/product_extract.py` runs that same file. Both entry points use `.env` beside the shared script. Do not run them as two consecutive steps. The package includes no actual credential file.

This module supersedes the earlier extraction version for this step. The previous version's 83,012-row check does not describe this Astrit version. The historical CSV in the original archive has 86,264 rows; it is not the acceptance count for regeneration from the raw source. The original Astrit README's 86,806-row example described an earlier result and is not the current verification count.

Original README illustration (historical screenshot, not evidence of a current execution):

<img width="369" height="176" alt="Original guide illustration" src="https://github.com/user-attachments/assets/7e5c12cd-62d3-48b4-9a47-dfcbd00c81a2" />
