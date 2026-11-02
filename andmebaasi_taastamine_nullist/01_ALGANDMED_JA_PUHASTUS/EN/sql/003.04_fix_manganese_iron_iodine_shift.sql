-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 01_ALGANDMED_JA_PUHASTUS | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- File: 003.04_fix_manganese_iron_iodine_shift.sql
-- Stage: 05 | Updated: 05.10.2026
-- Purpose: corrects manganese number text and confirmed Mn/Fe/I field shifts.
-- Prerequisite: stages 01–04 have passed; the same original CSV is used.
-- Expected result: 378 manganese, 1 iron and 1 iodine source rows have correct value/unit fields.
-- Changes: updates confirmed nutrient fields in vet_clean only; does not use the unit rules table.
-- Usage: open the file using the same target database connection and run the entire script (Alt+X).
-- If an error occurs, stop; use ROLLBACK if a transaction is open, and fix the cause.
-- For the exact sequence and interpretation of results, see README.md in the package root.

BEGIN;

-- 1. Target rows derived from the original source, rather than a count of remaining errors only.
CREATE TEMP TABLE tmp_vetsy_shift_targets ON COMMIT DROP AS
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
FROM vet_analytics.vet_raw AS r WHERE r._id = '691ce762f28d412bf11f0c22';

SELECT nutrient, count(*) AS source_target_rows
FROM tmp_vetsy_shift_targets GROUP BY nutrient ORDER BY nutrient;

-- Historical corrections are not applied automatically to a different source dataset.
DO $validation$
BEGIN
    IF (SELECT count(*) FROM tmp_vetsy_shift_targets WHERE nutrient = 'manganese') <> 378
       OR (SELECT count(*) FROM tmp_vetsy_shift_targets WHERE nutrient = 'iron') <> 1
       OR (SELECT count(*) FROM tmp_vetsy_shift_targets WHERE nutrient = 'iodine') <> 1
       OR EXISTS (SELECT 1 FROM tmp_vetsy_shift_targets
                  WHERE expected_value !~ '^[0-9]+([.][0-9]+)?$') THEN
        RAISE EXCEPTION 'The shift target rows do not match the original CSV for this package';
    END IF;
END;
$validation$;

-- 2. First correct the three manganese number-text typos (0..3, 1..5, 1..9).
UPDATE vet_analytics.vet_clean AS c
SET "minerals.manganese.unit" =
    regexp_replace(c."minerals.manganese.unit", '[.][.]', '.', 'g')
FROM vet_analytics.vet_raw AS r
WHERE c._id = r._id
  AND c."minerals.manganese.value" = '0'
  AND c."minerals..manganese.unit.1" = 'mg'
  AND c."minerals.manganese.unit" ~ '^[0-9]+[.][.][0-9]+$'
RETURNING
    c._id,
    c.product_name_fi,
    r."minerals.manganese.unit" AS original_text,
    c."minerals.manganese.unit" AS text_after;

-- 3. Then correct each nutrient in a separate SQL statement.
-- A product may require several nutrient corrections; sequential UPDATE statements
-- avoid updating the same row multiple times within a single WITH statement.
-- Manganese: the original target conditions and RETURNING output are preserved.
UPDATE vet_analytics.vet_clean AS c
    SET "minerals.manganese.value" = c."minerals.manganese.unit",
        "minerals.manganese.unit" = c."minerals..manganese.unit.1"
    FROM vet_analytics.vet_raw AS r
    WHERE c._id = r._id
      AND c."minerals.manganese.value" = '0'
      AND c."minerals..manganese.unit.1" = 'mg'
      AND c."minerals.manganese.unit" ~ '^[0-9]+([.][0-9]+)?$'
    RETURNING
        'manganese'::text AS nutrient, c._id, c.product_name_fi,
        r."minerals.manganese.value" AS original_value,
        r."minerals.manganese.unit" AS original_unit,
        c."minerals.manganese.value" AS new_value,
        c."minerals.manganese.unit" AS new_unit;

-- Iron: the original target conditions and RETURNING output are preserved.
UPDATE vet_analytics.vet_clean AS c
    SET "trace_elements.iron.value" = c."trace_elements.iron.unit",
        "trace_elements.iron.unit" = 'mg'
    FROM vet_analytics.vet_raw AS r
    WHERE c._id = r._id
      AND c._id = '691ce762f28d412bf11f0c46'
      AND c."trace_elements.iron.value" = '0'
      AND c."trace_elements.iron.unit" = '20'
    RETURNING
        'iron'::text AS nutrient, c._id, c.product_name_fi,
        r."trace_elements.iron.value" AS original_value,
        r."trace_elements.iron.unit" AS original_unit,
        c."trace_elements.iron.value" AS new_value,
        c."trace_elements.iron.unit" AS new_unit;

-- Iodine: the original target conditions and RETURNING output are preserved.
UPDATE vet_analytics.vet_clean AS c
    SET "minerals.iodine.value" = c."minerals.iodine.unit",
        "minerals.iodine.unit" = 'mg'
    FROM vet_analytics.vet_raw AS r
    WHERE c._id = r._id
      AND c._id = '691ce762f28d412bf11f0c22'
      AND c."minerals.iodine.value" = '0'
      AND c."minerals.iodine.unit" = '0.71'
    RETURNING
        'iodine'::text AS nutrient, c._id, c.product_name_fi,
        r."minerals.iodine.value" AS original_value,
        r."minerals.iodine.unit" AS original_unit,
        c."minerals.iodine.value" AS new_value,
        c."minerals.iodine.unit" AS new_unit;

-- 4. Post-check all target rows from the original source, including when rerunning the script.
WITH target_rows AS (SELECT * FROM tmp_vetsy_shift_targets),
current_values AS (
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
       count(*) FILTER (WHERE matched_id IS NULL OR current_unit IS DISTINCT FROM 'mg' OR current_value IS DISTINCT FROM expected_value) AS remaining_invalid_rows
FROM current_values GROUP BY nutrient ORDER BY nutrient;

DO $validation$
BEGIN
    IF EXISTS (
        WITH target_rows AS (SELECT * FROM tmp_vetsy_shift_targets),
        current_values AS (
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
        SELECT 1 FROM current_values WHERE matched_id IS NULL OR current_unit IS DISTINCT FROM 'mg' OR current_value IS DISTINCT FROM expected_value
    ) THEN
        RAISE EXCEPTION 'Shift post-check failed; changes will not be committed';
    END IF;
END;
$validation$;

COMMIT;
