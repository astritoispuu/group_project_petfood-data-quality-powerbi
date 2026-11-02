# Vet: original data import and confirmed cleanup

This guide covers a six-script stage: original CSV → `vet_raw` → corrected `vet_clean`. Stage numbers in the table below define the execution order. This English edition translates the documentation, SQL comments, messages, result headings, and package filenames; database object names and correction logic are preserved.

## What does this stage create?

| Object | Purpose | State at the end of this stage |
|---|---|---|
| `vet_analytics` | Project schema | Exists |
| `vet_analytics.vet_raw` | Original imported data used to verify corrections | 15,202 rows and 215 TEXT columns; cleanup scripts do not modify it |
| `vet_analytics.vet_clean` | Separate working copy | The same products and columns; confirmed typos and Mn/Fe/I field shifts corrected |
| `vet_clean_id_uq` | Unique index on `vet_clean._id` | Prevents duplicate IDs in the working copy |

Nutrient values in `vet_clean` remain text at this stage, and the `.value` and `.unit` columns remain present. Conversion to mg/kg, `vet_clean_bi`, ingredient categorization and the `vet_powerbi` model belong to later stages. This ZIP is not a backup of the entire current database.

## When should you use this sequence?

Use it **when starting from the original, uncleaned CSV**. If you are restoring an already cleaned `vet_clean` CSV or a fresh complete backup, follow the guide for that restore route. Do not run these three starting routes one after another.

You need a PostgreSQL server and DBeaver. Open all six scripts using the same target database connection. Use a new empty database, or a database that does not yet contain the project's `vet_analytics` schema. The schema creation script does not replace existing objects.

SQL files use UTF-8. In DBeaver, run the **entire script**, usually with Alt+X / Execute SQL Script. Do not execute only the statement under the cursor. Review each stage's results. If an error occurs, stop; run `ROLLBACK` if a transaction remains open, then fix the cause. Continue only when the current stage has completed without errors and its checks match this guide.

## Source file

The package includes `../data/vetsy_nutrition_readkorras (1) - Copy.csv`: 15,202 data rows and 215 columns. This is the original, uncleaned input. Do not substitute `vet_clean_2026-09-28.csv`.





## Exact execution order

The SQL files are in `sql`. Manual CSV import takes place between the first and second SQL scripts.

| Stage | Script or action | Purpose | When can you continue? |
|---|---|---|---|
| 01 | `001.01_create_schema_and_table.sql` | Creates the schema and empty `vet_raw` table | The script completed without errors and the table exists |
| Import | Import the original CSV into `vet_analytics.vet_raw` | Populates the source table | Import completed without errors; the next script validates counts and keys |
| 02 | `001.03_check_import.sql` | Validates rows, IDs, columns and types | 15,202 rows; 15,202 distinct IDs; 0 missing/duplicate IDs; 215 TEXT columns |
| 03 | `001.04_create_vet_clean.sql` | Creates an exact working copy and a unique index | Copy validation passed; both tables contain 15,202 rows |
| 04 | `002.09_find_and_fix_double_dots.sql` | Corrects errors in 26 value, four text and two category/type columns | `remaining_incorrect_cells` = 0 for all 32 target columns; the script completed without errors |
| 05 | `003.04_fix_manganese_iron_iodine_shift.sql` | Corrects three manganese typos first, then Mn/Fe/I shifts | 378 manganese, 1 iron and 1 iodine target rows; `remaining_invalid_rows` = 0 for each nutrient |
| 06 | `004.01_final_checks.sql` | Validates final counts, keys, structure and corrections | All required results in the table below match |

Stage numbers 01–06 also appear in the script headers. 
## Importing the CSV in DBeaver

1. After stage 01, refresh the object tree and select `vet_analytics.vet_raw`.
2. Right-click → **Import Data** → **CSV**. Select the source file included in this package.
3. Settings: **UTF-8**, separator **comma**, quote character **"**, first row contains column headers.
4. Use the existing empty `vet_raw` table as the target. Keep all 215 columns as **TEXT**. Empty cells may be NULL; do not automatically turn them into numeric zero.
5. Review the column mapping. Most headers match by name; the two long headers require the mapping shown below.
6. Import once. Save the import summary, including row and error counts. Run stage 02.

Reimporting into a table that already contains these rows creates duplicates. Import validation prevents that input from being used; do not proceed to working-copy creation.

### Two long headers

With the standard PostgreSQL configuration, table and column names are limited to 63 bytes. The original creation code uses the full CSV headers, so the server truncates two names. This is the existing code's behavior; this translation does not rename database columns. During import, map each full CSV header to its truncated target column.

| Full CSV header | PostgreSQL target column |
|---|---|
| `Tuotekategoria: 0. Täysravinto, 1. herkut, puruluut jne., 2. Täydennysravinto, 3. Öljyt 4. Elintarvikkeet, 5. BARF, 6. Lisäravinteet` | `Tuotekategoria: 0. Täysravinto, 1. herkut, puruluut jne., 2. T` |
| `0.. kuivaruoka, 1. Puolikostea, 2. Märkäruoka, 3. Lisäravinne, 4. BARF 5. Elintarvike` | `0.. kuivaruoka, 1. Puolikostea, 2. Märkäruoka, 3. Lisäravinn` |

Headers such as `minerals.calsium.value`, `vitamins..b1_vitamin.value` and `dry_matter..value` also retain their original spelling. Double-dot correction applies to **cell contents**, not headers.

## Interpreting corrections and checks

### Double dots

Stage 04 changes the digit..digit pattern only in the 32 confirmed columns: for example, `106..6666` → `106.6666` and `0..5%` → `0.5%`. The column list matches the supplied correction scripts. No persistent `value_text_anomalies` table is required. Before/after results are captured for the current run in a temporary table, which is removed at COMMIT. Export the results before closing the query window if you want to retain them.

The pre-check counts **incorrect cells by column**. The UPDATE summaries count **updated rows by correction group**. A product may contain several incorrect cells and appear in several groups; adding the group row counts does not give the number of distinct products.

The manganese unit column is not one of these 32 columns. Its three number-text typos are corrected in stage 05. Therefore, stage 04 does not yet require the digit..digit count across the entire table to be zero.

### Field shifts

Stage 05 moves confirmed numbers from unit fields into value fields and sets the unit to `mg`. It does not convert units to mg/kg or change zero values in other products.

The script first confirms that the original data contains 378 manganese, 1 iron and 1 iodine target rows. A different source causes an error; historical exception rules must be reassessed before applying them to another source.

The post-check uses **all target rows derived from the source table**. It therefore shows the final result even if rerunning UPDATE changes no rows. After successful correction, repeated UPDATE results may be empty, but the post-check must still pass.

### Required final-check results

| Check | Expected result |
|---|---|
| Row and distinct-ID counts in both main tables | 15,202 in each |
| Missing IDs and ID differences between raw/clean | All 0 |
| Column count / non-TEXT columns | 215 / 0 in each |
| Structure differences | 0 |
| |
| `digit_double_dot_digit_rows` | 0 |
| Shift check | Three rows: iodine 1, manganese 378, iron 1; invalid rows 0 for each |
| Five example rows | Manganese values 0.3, 1.9 and 1.5 for the specified IDs; iron 20; iodine 0.71; all units mg |
| Product name check | Original CSV: missing FI 3; missing FI with EN available 0; both names missing 3 |

`other_double_dot_rows` is a separate **review indicator** that may exceed zero. Free text may contain strings such as `L.I..P.`. The local check of the original CSV left 210 such rows. They are not corrected automatically and do not mean the numeric-typo check has failed.

Missing product names are a data-quality finding, not an import error. This package does not invent names. 

## Package folders

| Folder | Contents |
|---|---|
| `../data` | Original, uncleaned CSV with unchanged bytes |
| `sql` | Six main scripts |
| `../../00_JUHEND_JA_LOGI/varasemad_logid` | Change log, execution template, file manifest and filename mapping |
| `../../90_VALIKULISED_KONTROLLID` | Product-name update for an existing unit audit ||

H

## Old-to-new filename mapping

The main script and optional-script mappings are:

| Previous filename | English filename |
|---|---|
| `001.01_skeemi_tabeli_loomine.sql` | `001.01_create_schema_and_table.sql` |
| `001.03_impordi_kontroll.sql` | `001.03_check_import.sql` |
| `001.04_vet_clean_tookoopia.sql` | `001.04_create_vet_clean_working_copy.sql` |
| `002.09_topeltpunktide_leidmine_parandamine.sql` | `002.09_find_and_fix_double_dots.sql` |
| `003.04_mangaa_raud_jood_nihe.sql` | `003.04_fix_manganese_iron_iodine_shift.sql` |
| `004.01_loppkontroll.sql` | `004.01_final_checks.sql` |
| `002.03_audititabeli_tootenimed.sql` | `002.03_fill_audit_product_names.sql` |

## How this fits into the future complete guide

Use this chapter as the **original-CSV route's import and cleanup stage**. Its output is `vet_analytics.vet_clean`. The next chapter must clearly describe creation of mg/kg conversion functions and the converted table, conversion validation, and creation of `vet_clean_bi`; ingredients and the `vet_powerbi` model follow afterward. Starting from a cleaned checkpoint or a complete backup should be described as separate branches.


