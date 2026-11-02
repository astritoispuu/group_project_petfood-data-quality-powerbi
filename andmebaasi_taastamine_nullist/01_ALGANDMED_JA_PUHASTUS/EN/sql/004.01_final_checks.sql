-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 01_ALGANDMED_JA_PUHASTUS | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- File: 004.01_final_checks.sql
-- Stage: 06 | Updated: 05.10.2026
-- Purpose: validates main table counts, structure and confirmed correction results.
-- Prerequisite: the five preceding main scripts have completed successfully.
-- Expected result: validation results match the README table; audit tables are not required.
-- Changes: no data changes or persistent object creation; SELECT queries only.
-- Usage: open the file using the same target database connection and run the entire script (Alt+X).
-- If an error occurs, stop; use ROLLBACK if a transaction is open, and fix the cause.
-- For the exact sequence and interpretation of results, see README.md in the package root.

-- 1. Main table rows and keys. Each table must contain 15,202 rows and distinct IDs.
SELECT 'vet_raw' AS table_name, count(*) AS row_count, count(DISTINCT _id) AS distinct_ids,
       count(*) FILTER (WHERE NULLIF(btrim(_id), '') IS NULL) AS missing_ids
FROM vet_analytics.vet_raw
UNION ALL
SELECT 'vet_clean', count(*), count(DISTINCT _id),
       count(*) FILTER (WHERE NULLIF(btrim(_id), '') IS NULL)
FROM vet_analytics.vet_clean;

-- The missing-ID count must be 0 in both directions.
SELECT count(*) FILTER (WHERE c._id IS NULL) AS ids_missing_from_clean,
       count(*) FILTER (WHERE r._id IS NULL) AS ids_missing_from_raw
FROM vet_analytics.vet_raw AS r
FULL JOIN vet_analytics.vet_clean AS c ON c._id = r._id;

-- 2. Column counts and types: 215 TEXT columns in each table.
SELECT table_name, count(*) AS column_count,
       count(*) FILTER (WHERE data_type <> 'text') AS non_text_columns
FROM information_schema.columns
WHERE table_schema = 'vet_analytics' AND table_name IN ('vet_raw', 'vet_clean')
GROUP BY table_name ORDER BY table_name;

-- Column names, positions and types must match; expected result: 0.
WITH r AS (
    SELECT column_name, ordinal_position, data_type
    FROM information_schema.columns
    WHERE table_schema = 'vet_analytics' AND table_name = 'vet_raw'
), c AS (
    SELECT column_name, ordinal_position, data_type
    FROM information_schema.columns
    WHERE table_schema = 'vet_analytics' AND table_name = 'vet_clean'
)
SELECT count(*) AS structure_differences
FROM r FULL JOIN c USING (column_name)
WHERE r.ordinal_position IS DISTINCT FROM c.ordinal_position
   OR r.data_type IS DISTINCT FROM c.data_type;

-- The unique ID index must exist; the query returns one row.
SELECT indexname, indexdef FROM pg_indexes
WHERE schemaname = 'vet_analytics' AND tablename = 'vet_clean'
  AND indexname = 'vet_clean_id_uq';

-- 3. Search all row data for the confirmed digit..digit pattern; expected result: 0.
SELECT count(*) FILTER (WHERE c::text ~ '[0-9][.][.][0-9]') AS digit_double_dot_digit_rows
FROM vet_analytics.vet_clean AS c;

-- An occurrence of '..' in free text is not automatically an error.
-- This indicator is not required to be 0; review the remaining examples separately.
SELECT count(*) FILTER (WHERE c::text LIKE '%..%') AS other_double_dot_rows
FROM vet_analytics.vet_clean AS c;

SELECT c._id, c.product_name_fi,
       substring(c::text FROM '.{0,50}[.][.].{0,50}') AS double_dot_context
FROM vet_analytics.vet_clean AS c
WHERE c::text LIKE '%..%' ORDER BY c._id LIMIT 30;

-- 4. Final check of the shift target rows. LEFT JOIN also exposes missing products.
WITH target_rows AS (
SELECT 'manganese'::text AS nutrient, r._id,
       r."minerals.manganese.unit" AS original_number_in_unit_field,
       replace(r."minerals.manganese.unit", '..', '.') AS expected_value
FROM vet_analytics.vet_raw AS r
WHERE r."minerals.manganese.value" = '0'
  AND r."minerals..manganese.unit.1" = 'mg'
  AND NULLIF(btrim(r."minerals.manganese.unit"), '') IS NOT NULL
  AND btrim(r."minerals.manganese.unit") <> 'mg'
UNION ALL
SELECT 'iron', r._id, r."trace_elements.iron.unit", '20'
FROM vet_analytics.vet_raw AS r WHERE r._id = '691ce762f28d412bf11f0c46'
UNION ALL
SELECT 'iodine', r._id, r."minerals.iodine.unit", '0.71'
FROM vet_analytics.vet_raw AS r WHERE r._id = '691ce762f28d412bf11f0c22'
), current_values AS (
SELECT s.*,
       c._id AS matched_id,
       CASE s.nutrient
           WHEN 'manganese' THEN c."minerals.manganese.value"
           WHEN 'iron' THEN c."trace_elements.iron.value"
           ELSE c."minerals.iodine.value"
       END AS current_value,
       CASE s.nutrient
           WHEN 'manganese' THEN c."minerals.manganese.unit"
           WHEN 'iron' THEN c."trace_elements.iron.unit"
           ELSE c."minerals.iodine.unit"
       END AS current_unit
FROM target_rows AS s
LEFT JOIN vet_analytics.vet_clean AS c ON c._id = s._id
)
SELECT nutrient, count(*) AS originally_shifted_rows,
       count(*) FILTER (WHERE NOT (matched_id IS NULL OR current_unit IS DISTINCT FROM 'mg' OR current_value IS DISTINCT FROM expected_value)) AS correct_rows,
       count(*) FILTER (WHERE matched_id IS NULL OR current_unit IS DISTINCT FROM 'mg' OR current_value IS DISTINCT FROM expected_value) AS remaining_invalid_rows,
       min(_id) FILTER (WHERE matched_id IS NULL OR current_unit IS DISTINCT FROM 'mg' OR current_value IS DISTINCT FROM expected_value) AS example_invalid_row_id
FROM current_values GROUP BY nutrient ORDER BY nutrient;

-- 5. Five known example rows. Missing products remain in the output with NULL values.
WITH target_rows(nutrient, _id) AS (
    VALUES
        ('manganese', '67441cded15392af62f791c5'),
        ('manganese', '67441cded15392af62f7924b'),
        ('manganese', '67441cded15392af62f793f7'),
        ('iron',    '691ce762f28d412bf11f0c46'),
        ('iodine',    '691ce762f28d412bf11f0c22')
)
SELECT s.nutrient, s._id, c.product_name_fi,
       CASE s.nutrient
           WHEN 'manganese' THEN r."minerals.manganese.value"
           WHEN 'iron' THEN r."trace_elements.iron.value"
           ELSE r."minerals.iodine.value"
       END AS original_value,
       CASE s.nutrient
           WHEN 'manganese' THEN r."minerals.manganese.unit"
           WHEN 'iron' THEN r."trace_elements.iron.unit"
           ELSE r."minerals.iodine.unit"
       END AS original_unit,
       CASE s.nutrient
           WHEN 'manganese' THEN c."minerals.manganese.value"
           WHEN 'iron' THEN c."trace_elements.iron.value"
           ELSE c."minerals.iodine.value"
       END AS new_value,
       CASE s.nutrient
           WHEN 'manganese' THEN c."minerals.manganese.unit"
           WHEN 'iron' THEN c."trace_elements.iron.unit"
           ELSE c."minerals.iodine.unit"
       END AS new_unit
FROM target_rows AS s
LEFT JOIN vet_analytics.vet_raw AS r ON r._id = s._id
LEFT JOIN vet_analytics.vet_clean AS c ON c._id = s._id
ORDER BY s.nutrient, s._id;

-- 6. Product name availability. COUNT FILTER counts only rows meeting the condition.
-- This check does not fill or change names in vet_clean.
SELECT count(*) AS total_products,
       count(*) FILTER (WHERE NULLIF(btrim(product_name_fi), '') IS NULL)
           AS missing_finnish_name,
       count(*) FILTER (WHERE NULLIF(btrim(product_name_fi), '') IS NULL
                          AND NULLIF(btrim(product_name_en), '') IS NOT NULL)
           AS missing_fi_with_en_available,
       count(*) FILTER (WHERE NULLIF(btrim(product_name_fi), '') IS NULL
                          AND NULLIF(btrim(product_name_en), '') IS NULL)
           AS both_names_missing
FROM vet_analytics.vet_clean;
