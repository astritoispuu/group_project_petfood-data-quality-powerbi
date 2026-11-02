
# Pet-food nutrient normalization — Oksana's SQL workflow

Original SQL functions, conversion factors and the 49 nutrient mappings were created by **Oksana**. This revision adds compatibility checks for `vet_analytics.vet_clean`, improves validation and connects the final output to the existing `vet_clean_bi` workflow. The source table and its headers are preserved.

## Scope and prerequisites

This is the **normalization stage** of database reconstruction. It does not restore the database from an empty server. Before using it, create/import `vet_analytics.vet_raw`, create `vet_analytics.vet_clean` and complete the earlier cleaning steps, including double-dot value corrections and displaced manganese/iron/iodine values.

Use PostgreSQL through DBeaver or another SQL client. Connect to the database containing `vet_analytics.vet_clean`. The connected role must be able to read the source, create/replace the two functions, create tables in `vet_analytics` and replace any existing output tables it owns. Validation uses a temporary table and therefore requires the database TEMP privilege.

The package reads the database directly. It does not read a CSV, Excel file or local data folder.

The screenshot confirms table names, but does not show `vet_clean` column names or data types. Compatibility with the current database must therefore be checked by running `00_check_vet_clean.sql` and the header checks built into step 02. This review did not access or execute SQL against your PostgreSQL database.

## Files and execution order

| Order | File | Purpose | Persistent effect |
|---|---|---|---|
| 0 | `sql/00_check_vet_clean.sql` | List actual source headers/types; check row count and product IDs | None |
| 1 | `sql/01_create_functions.sql` | Create Oksana's two conversion functions | Creates/replaces two functions |
| 2 | `sql/02_create_normalized_table.sql` | Validate required source headers and build the intermediate table | Rebuilds `vet_analytics.vet_clean_mg_kg` |
| 3 | `sql/03_validation.sql` | Review all 49 conversions, missing results and unmapped measurements | Creates a session-local temporary review table |
| 4 | `sql/04_AINULT_mg_kg.sql` | Build the existing BI input table and check its row count/headers | Rebuilds `vet_analytics.vet_clean_bi` |
| Optional | `optional/05_function_checks.sql` | Check 22 examples of the conversion functions after step 1 | None |

The original archive contains the four supplied SQL files, the supplied README and the schema screenshot, unchanged. Do not run these as additional steps. Their purpose is traceability and attribution. The active validation filename is `03_validation.sql`; the extra trailing underscore from the upload is removed in this package.

## Running in DBeaver

1. Open `00_check_vet_clean.sql` on the correct database connection and execute it. Review the source headers and types. Export the header result if any required field is missing. Empty/duplicate `_id` values need review before a one-to-many BI relationship is created.
2. Execute the complete `01_create_functions.sql` script. It creates `vet_analytics.convert_to_mg_kg(text, text)` and `vet_analytics.convert_vitamin_to_mg_kg(text, text, text)`.
3. Execute the complete `02_create_normalized_table.sql` script. It verifies all fixed column names before replacing the output. It reports the actual B1 source headers in a NOTICE message.
4. Execute `03_validation.sql` in one database session. Review every result, especially populated inputs whose normalized output is NULL. Do not interpret a matching row count as proof that every nutrient was converted correctly.
5. Once the review is satisfactory, execute the complete `04_AINULT_mg_kg.sql` script. Check that all three table row counts match and that the raw measurement header check returns zero rows.
6. Run your separate scripts that build/refresh `vet_powerbi` dimension and fact tables from `vet_clean_bi`, then refresh Power BI. This package does not rebuild the BI star schema or classify ingredients.

For files containing `BEGIN` and `COMMIT`, use DBeaver's **Execute SQL Script** action so the whole file runs in order. Configure execution to stop on errors. If a script fails and the transaction remains open, execute `ROLLBACK;` before retrying. If using manual transaction mode, finish any earlier transaction first.

The output tables are snapshots. Source data changes are not reflected until the creation steps are rerun. Run the validation again after rebuilding them.

## Matching the actual vet_clean structure

Step 02 retains Oksana's explicit SELECT and all 49 output aliases. Source values and units are passed with `::text` so the functions also work when `.value` columns were already converted to numeric. Casting for the function call does not change the source types or the types of copied source columns.

For B1 only, the script matches either `vitamins..b1_vitamin.value` or `vitamins.b1_vitamin.value`, and either corresponding spelling of the unit header. It requires exactly one value header and exactly one unit header. If both variants exist or neither exists, it stops instead of guessing. No header is renamed.

Other source names must match the supplied mapping exactly. This includes `minerals.calsium.*`, `minerals.phosphorous.*` and `proteins.digestible_protein_from_AA.*`. Output names such as `calsium_mg_kg` and `phosphorous_mg_kg` are retained so dependent scripts are not broken by spelling corrections.

Missing required headers cause a readable error before the previous intermediate table is dropped. Pre-existing source columns with one of the 49 output aliases also cause an error, because copying `v.*` and adding the same alias would produce duplicate headers.

The CSV lists Oksana's original B1 spelling; the automatic B1 alternatives are described above. It is a reference document, not an additional database input.

## Data flow and final table

| Object | Contents |
|---|---|
| `vet_analytics.vet_clean` | Existing cleaned source, unchanged |
| `vet_analytics.vet_clean_mg_kg` | Every source column plus Oksana's 49 normalized numeric columns |
| `vet_analytics.vet_clean_bi` | Every intermediate column except headers containing `.value`, `.valu` or `.unit`, matched without case sensitivity |

The original step 04 selected only 17 fixed metadata columns and created `vet_ainult_mg_kg`. The revised step uses the existing BI input name **`vet_clean_bi`** and derives its column list from the actual intermediate table. Metadata such as species, product content and found ingredient fields is retained if it exists in the source and its header does not contain one of the excluded tokens. Their original names and types are kept, including `_id`.

The source raw value/unit fields remain available in `vet_clean` and `vet_clean_mg_kg` for auditing. No separate `vet_ainult_mg_kg` is created. An existing table with that name is not deleted by this package.

`vet_powerbi.fact_ingredients`, `dim_ingredients` and other BI tables are not modified. Product-name Finnish-to-English fallback and renaming `_id` to `product_id` are not performed here; those belong to separate agreed transformation steps.

## Conversion rules retained from Oksana

| Input unit after trimming/lowercasing | Factor to mg/kg | Interpretation |
|---|---:|---|
| `mg/kg`, `mg na kg` | 1 | Explicit mass per kg |
| `mg` | 1 | Project assumption: the label amount is per kg |
| `g/kg`, `g na kg` | 1000 | Explicit mass per kg |
| `g` | 1000 | Project assumption: the label amount is per kg |
| `µg/kg`, `μg/kg`, `ug/kg`, `mcg/kg` | 0.001 | Explicit mass per kg |
| `µg`, `μg`, `ug`, `mcg` | 0.001 | Project assumption: the label amount is per kg |
| `%` | 10000 | Mass percentage: 1% = 10 g/kg = 10000 mg/kg |
| `IU`, `IE` for vitamin A | 0.0003 | Retinol-equivalent mg, with the project per-kg basis assumption |
| `IU`, `IE` for vitamin D3 | 0.000025 | Cholecalciferol mg, with the project per-kg basis assumption |
| `IU`, `IE` for vitamin E | 1 | All-rac-alpha-tocopheryl acetate mg, with the project per-kg basis assumption |

**Mass and concentration differ.** `66740 mg` is only `66740 mg/kg` if the label explicitly or contextually reports that amount per kilogram. If it is per 100 g, the mg/kg concentration would be ten times higher. The retained standalone-unit rules are assumptions inherited from this dataset's workflow, not universal unit identities. Validation lists populated inputs using these units for review.

**The percentage rule remains necessary.** It converts protein, fat and other mass percentages into mg/kg. The rule is already inside the conversion function; this package needs no separate percentage-rule SQL script or table.

### Vitamin E: the IU conversion stays

Oksana's `value × 1` rule is retained. It is a documented animal-feed convention for **all-rac-alpha-tocopheryl acetate**, not a universal conversion for every form of vitamin E. The SQL does not inspect the ingredient list or identify the chemical form.

EFSA's feed assessment gives the following form-specific equivalences:

| Vitamin E form | Equivalence | mg per IU of the named form |
|---|---|---:|
| All-rac-alpha-tocopheryl acetate | 1 mg = 1 IU | 1 |
| RRR-alpha-tocopherol | 1 mg = 1.49 IU | 1 / 1.49 |
| RRR-alpha-tocopheryl acetate | 1 mg = 1.36 IU | 1 / 1.36 |

Do not apply a human alpha-tocopherol-equivalent conversion to this dataset without defining what the output is meant to represent. If the source uses a different vitamin E form, verify the original label and agree a form-aware rule before changing this function. Until the source form is confirmed, E IU outputs remain conditional on the documented assumption. No E IU values were deliberately excluded by this revision.

Vitamin A's factor represents retinol-equivalent mass and must not be read as the physical mass of retinyl acetate or retinyl palmitate.

## Values, precision and unsupported units

- Missing or empty input values return NULL.
- Decimal commas are replaced with decimal points; `2,5` becomes `2.5`.
- Unicode minus signs are replaced with an ordinary minus sign.
- Invalid numeric text, numeric overflow, NaN and Infinity return NULL.
- Zero stays zero. Negative numbers remain numeric and are listed for review.
- Units are trimmed and converted to lowercase; internal whitespace is not normalized.
- Unknown or missing units return NULL, even if the value itself is numeric.
- `mg/100g`, `g/100g`, `IU/kg`, `IE/kg`, `per 1000 kcal` and similar variants are **not supported by the retained CASE rules**. Validation exposes populated inputs that could not be converted; it does not silently invent a basis.
- kcal/kJ are energy and cannot be converted to mg/kg by these mass functions.

All 49 outputs use PostgreSQL **numeric with unrestricted scale**. No `ROUND(..., 3)` or `numeric(..., 3)` is applied. At least three decimal places can be displayed in a client, but storage must preserve smaller amounts. For example, `0.6 µg/kg = 0.0006 mg/kg` and `1 IU D3/kg = 0.000025 mg/kg`; rounding either to three decimal places would lose information. The D3 example states the physical unit relationship; a literal source string `IU/kg` is not accepted by the current function.

## What is and is not normalized

The original 49 mappings cover proteins, basic nutrients, vitamins, two linoleic-acid source fields, trace elements, minerals, amino acids, choline and NFE. The CSV is the complete authoritative list for this package.

`dry_matter`, `moisture`, energy and other fields not listed in the mapping are not given new mg/kg columns. Step 03 lists unmapped source `.value` headers. If a business requirement needs an additional nutrient, add its verified source pair and intended conversion deliberately; do not assume every field is covered.

Unmapped raw `.value`/`.unit` measurements remain in the source and intermediate table but are excluded from the BI input by step 04. Standalone fields without an excluded header token remain in the BI input, unchanged. This corrects the old README's broad statement that all excluded nutrients remain in the final table.

Sodium and natrium, and the two linoleic-acid fields, are kept separately as Oksana mapped them. Copper sulfate is compound mass, not automatically elemental copper mass. Combining any of these requires a separate agreed rule.

## Validation and acceptance

Step 03 creates `normalization_review` as a **temporary** tall table in the current session. It uses SQL `CROSS JOIN LATERAL (VALUES ...)` without JSON. Run the complete validation file in the same session; a reconnect removes the temporary table.

| Check | Acceptance/review action |
|---|---|
| Source/intermediate/final row counts | Must match the current source; 15,202 is a historical baseline, not a hard-coded condition |
| Final raw measurement headers | Query in step 04 must return zero rows |
| Output types | All 49 normalization outputs must be numeric |
| Populated input + NULL normalized output | Review unsupported units, invalid numbers and missing units; document accepted exclusions |
| Negative outputs | Review source data; do not automatically replace with zero |
| Standalone mass/IU units | Confirm that the source declaration is per kg |
| E IU inputs | Confirm the form assumption before treating results as chemically verified |
| Unmapped source measurements | Decide whether exclusion from BI is acceptable |
| Optional 22 function checks | Every `passed` value must be true |

Repeated whole-column unit frequency queries from the original validation file have been replaced by focused review of conversion coverage and losses. These queries are diagnostic: they do not change any source values and do not themselves prove scientific correctness.

## Reruns, dependencies and other project tables

Steps 02 and 04 use transactions around DROP/CREATE. A failure must be rolled back. They intentionally do not use CASCADE. If an existing view depends on the output, PostgreSQL stops the replacement rather than deleting that view; inspect and rebuild the known dependency as part of the separate workflow.

CREATE TABLE AS creates data snapshots; it does not copy source indexes, constraints, grants, triggers or primary keys. Any output-specific indexes/grants added later must be reapplied after rebuilding. Product identifier checks in step 00 are diagnostics and do not create a primary key.

Neither conversion function reads `unit_normalization_rules`, `unit_anomalies` or a separate percentage-rule table. Those tables are not prerequisites for this package. Keep or remove them based on their use elsewhere in the full project; their presence in the screenshot alone is not evidence that they are redundant. This revision deletes none of them. Any persistent outlier/analysis tables based on older outputs need their own refresh after normalization changes.

## References

- [EFSA feed vitamin E assessment, 2021 — form-specific IU equivalences, section 3.1.4](https://efsa.onlinelibrary.wiley.com/doi/10.2903/j.efsa.2021.6531)
- [USDA/NIH DSID unit conversions — vitamin A and D](https://dsid.od.nih.gov/unit-conversions)
- [PostgreSQL dynamic SQL and identifier quoting](https://www.postgresql.org/docs/17/plpgsql-statements.html)

These references explain unit conventions and SQL construction. They do not verify the basis or chemical form of any particular product in the source dataset.
