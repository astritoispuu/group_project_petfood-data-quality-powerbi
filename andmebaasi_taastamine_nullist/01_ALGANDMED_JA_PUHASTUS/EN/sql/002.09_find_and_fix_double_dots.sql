-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 01_ALGANDMED_JA_PUHASTUS | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- File: 002.09_find_and_fix_double_dots.sql
-- Stage: 04 | Updated: 05.10.2026
-- Purpose: finds and corrects digit..digit errors in 32 confirmed columns.
-- Prerequisite: vet_raw and vet_clean exist and the import has been validated.
-- Expected result: no digit..digit errors in the 32 target columns. The manganese unit field is corrected in the next stage.
-- Changes: updates vet_clean cell contents; preserves vet_raw, column names and columns outside the target list.
-- Usage: open the file using the same target database connection and run the entire script (Alt+X).
-- If an error occurs, stop; use ROLLBACK if a transaction is open, and fix the cause.
-- For the exact sequence and interpretation of results, see README.md in the package root.

BEGIN;

-- 1. Pre-check directly against vet_clean; persistent audit tables are not required.
-- One record represents one incorrect cell, not necessarily one distinct product.
CREATE TEMP TABLE tmp_vetsy_double_dots_before ON COMMIT DROP AS
SELECT c._id AS product_id,
       COALESCE(NULLIF(btrim(c.product_name_fi), ''),
                NULLIF(btrim(c.product_name_en), '')) AS product_name,
       v.column_name, v.correction_group, v.value_text AS value_before
FROM vet_analytics.vet_clean AS c
CROSS JOIN LATERAL (VALUES
        ('aminoacids.lysine.value', 'values', c."aminoacids.lysine.value"),
        ('convertible_energy.value', 'values', c."convertible_energy.value"),
        ('minerals.calsium.value', 'values', c."minerals.calsium.value"),
        ('minerals.iodine.value', 'values', c."minerals.iodine.value"),
        ('minerals.magnesium.value', 'values', c."minerals.magnesium.value"),
        ('minerals.manganese.value', 'values', c."minerals.manganese.value"),
        ('minerals.phosphorous.value', 'values', c."minerals.phosphorous.value"),
        ('minerals.selenium.value', 'values', c."minerals.selenium.value"),
        ('minerals.sodium.value', 'values', c."minerals.sodium.value"),
        ('moisture.value', 'values', c."moisture.value"),
        ('proteins.crude_protein.value', 'values', c."proteins.crude_protein.value"),
        ('trace_elements.copper.value', 'values', c."trace_elements.copper.value"),
        ('trace_elements.copper_sulfate.value', 'values', c."trace_elements.copper_sulfate.value"),
        ('trace_elements.iron.value', 'values', c."trace_elements.iron.value"),
        ('trace_elements.zinc.value', 'values', c."trace_elements.zinc.value"),
        ('vitamins..b1_vitamin.value', 'values', c."vitamins..b1_vitamin.value"),
        ('vitamins.a_vitamin.value', 'values', c."vitamins.a_vitamin.value"),
        ('vitamins.b12_vitamin.value', 'values', c."vitamins.b12_vitamin.value"),
        ('vitamins.b2_vitamin.value', 'values', c."vitamins.b2_vitamin.value"),
        ('vitamins.b6_vitamin.value', 'values', c."vitamins.b6_vitamin.value"),
        ('vitamins.biotin.value', 'values', c."vitamins.biotin.value"),
        ('vitamins.d3_vitamin.value', 'values', c."vitamins.d3_vitamin.value"),
        ('vitamins.e_vitamin.value', 'values', c."vitamins.e_vitamin.value"),
        ('vitamins.folic_acid.value', 'values', c."vitamins.folic_acid.value"),
        ('vitamins.niacin.value', 'values', c."vitamins.niacin.value"),
        ('vitamins.pantothenic_acid.value', 'values', c."vitamins.pantothenic_acid.value"),
        ('product_content', 'text', c."product_content"),
        ('product_additives', 'text', c."product_additives"),
        ('product_carbohydrates_source', 'text', c."product_carbohydrates_source"),
        ('product_name_en', 'text', c."product_name_en"),
        ('product_category', 'category_type', c."product_category"),
        ('product_type', 'category_type', c."product_type")
) AS v(column_name, correction_group, value_text)
WHERE v.value_text ~ '[0-9][.][.][0-9]';

SELECT correction_group, column_name, count(*) AS incorrect_cells_before
FROM tmp_vetsy_double_dots_before
GROUP BY correction_group, column_name ORDER BY correction_group, column_name;

-- 2. Corrections. Replace two dots with one only when they occur between digits.
-- The lookahead/lookbehind pattern also corrects 1..2..3 -> 1.2.3 in one pass.
-- This corrects the text format; it does not automatically convert text to numeric.
-- Update the confirmed value columns only, and only rows matching the pattern.
WITH updated AS (
    UPDATE vet_analytics.vet_clean AS c
    SET
    "aminoacids.lysine.value" = regexp_replace("aminoacids.lysine.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "convertible_energy.value" = regexp_replace("convertible_energy.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "minerals.calsium.value" = regexp_replace("minerals.calsium.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "minerals.iodine.value" = regexp_replace("minerals.iodine.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "minerals.magnesium.value" = regexp_replace("minerals.magnesium.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "minerals.manganese.value" = regexp_replace("minerals.manganese.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "minerals.phosphorous.value" = regexp_replace("minerals.phosphorous.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "minerals.selenium.value" = regexp_replace("minerals.selenium.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "minerals.sodium.value" = regexp_replace("minerals.sodium.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "moisture.value" = regexp_replace("moisture.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "proteins.crude_protein.value" = regexp_replace("proteins.crude_protein.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "trace_elements.copper.value" = regexp_replace("trace_elements.copper.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "trace_elements.copper_sulfate.value" = regexp_replace("trace_elements.copper_sulfate.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "trace_elements.iron.value" = regexp_replace("trace_elements.iron.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "trace_elements.zinc.value" = regexp_replace("trace_elements.zinc.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "vitamins..b1_vitamin.value" = regexp_replace("vitamins..b1_vitamin.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "vitamins.a_vitamin.value" = regexp_replace("vitamins.a_vitamin.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "vitamins.b12_vitamin.value" = regexp_replace("vitamins.b12_vitamin.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "vitamins.b2_vitamin.value" = regexp_replace("vitamins.b2_vitamin.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "vitamins.b6_vitamin.value" = regexp_replace("vitamins.b6_vitamin.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "vitamins.biotin.value" = regexp_replace("vitamins.biotin.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "vitamins.d3_vitamin.value" = regexp_replace("vitamins.d3_vitamin.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "vitamins.e_vitamin.value" = regexp_replace("vitamins.e_vitamin.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "vitamins.folic_acid.value" = regexp_replace("vitamins.folic_acid.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "vitamins.niacin.value" = regexp_replace("vitamins.niacin.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "vitamins.pantothenic_acid.value" = regexp_replace("vitamins.pantothenic_acid.value", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g')
    WHERE c."aminoacids.lysine.value" ~ '[0-9][.][.][0-9]'
   OR c."convertible_energy.value" ~ '[0-9][.][.][0-9]'
   OR c."minerals.calsium.value" ~ '[0-9][.][.][0-9]'
   OR c."minerals.iodine.value" ~ '[0-9][.][.][0-9]'
   OR c."minerals.magnesium.value" ~ '[0-9][.][.][0-9]'
   OR c."minerals.manganese.value" ~ '[0-9][.][.][0-9]'
   OR c."minerals.phosphorous.value" ~ '[0-9][.][.][0-9]'
   OR c."minerals.selenium.value" ~ '[0-9][.][.][0-9]'
   OR c."minerals.sodium.value" ~ '[0-9][.][.][0-9]'
   OR c."moisture.value" ~ '[0-9][.][.][0-9]'
   OR c."proteins.crude_protein.value" ~ '[0-9][.][.][0-9]'
   OR c."trace_elements.copper.value" ~ '[0-9][.][.][0-9]'
   OR c."trace_elements.copper_sulfate.value" ~ '[0-9][.][.][0-9]'
   OR c."trace_elements.iron.value" ~ '[0-9][.][.][0-9]'
   OR c."trace_elements.zinc.value" ~ '[0-9][.][.][0-9]'
   OR c."vitamins..b1_vitamin.value" ~ '[0-9][.][.][0-9]'
   OR c."vitamins.a_vitamin.value" ~ '[0-9][.][.][0-9]'
   OR c."vitamins.b12_vitamin.value" ~ '[0-9][.][.][0-9]'
   OR c."vitamins.b2_vitamin.value" ~ '[0-9][.][.][0-9]'
   OR c."vitamins.b6_vitamin.value" ~ '[0-9][.][.][0-9]'
   OR c."vitamins.biotin.value" ~ '[0-9][.][.][0-9]'
   OR c."vitamins.d3_vitamin.value" ~ '[0-9][.][.][0-9]'
   OR c."vitamins.e_vitamin.value" ~ '[0-9][.][.][0-9]'
   OR c."vitamins.folic_acid.value" ~ '[0-9][.][.][0-9]'
   OR c."vitamins.niacin.value" ~ '[0-9][.][.][0-9]'
   OR c."vitamins.pantothenic_acid.value" ~ '[0-9][.][.][0-9]'
    RETURNING _id
)
SELECT 'values' AS correction_group, count(*) AS updated_rows FROM updated;

-- Update the confirmed text columns only, and only rows matching the pattern.
WITH updated AS (
    UPDATE vet_analytics.vet_clean AS c
    SET
    "product_content" = regexp_replace("product_content", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "product_additives" = regexp_replace("product_additives", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "product_carbohydrates_source" = regexp_replace("product_carbohydrates_source", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "product_name_en" = regexp_replace("product_name_en", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g')
    WHERE c."product_content" ~ '[0-9][.][.][0-9]'
   OR c."product_additives" ~ '[0-9][.][.][0-9]'
   OR c."product_carbohydrates_source" ~ '[0-9][.][.][0-9]'
   OR c."product_name_en" ~ '[0-9][.][.][0-9]'
    RETURNING _id
)
SELECT 'text' AS correction_group, count(*) AS updated_rows FROM updated;

-- Update the confirmed category/type columns only, and only rows matching the pattern.
WITH updated AS (
    UPDATE vet_analytics.vet_clean AS c
    SET
    "product_category" = regexp_replace("product_category", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "product_type" = regexp_replace("product_type", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g')
    WHERE c."product_category" ~ '[0-9][.][.][0-9]'
   OR c."product_type" ~ '[0-9][.][.][0-9]'
    RETURNING _id
)
SELECT 'category_type' AS correction_group, count(*) AS updated_rows FROM updated;


-- 3. Post-check of exactly the same 32 columns; expected result: 0 on every row.
SELECT v.correction_group, v.column_name,
       count(*) FILTER (WHERE v.value_text ~ '[0-9][.][.][0-9]') AS remaining_incorrect_cells
FROM vet_analytics.vet_clean AS c
CROSS JOIN LATERAL (VALUES
        ('aminoacids.lysine.value', 'values', c."aminoacids.lysine.value"),
        ('convertible_energy.value', 'values', c."convertible_energy.value"),
        ('minerals.calsium.value', 'values', c."minerals.calsium.value"),
        ('minerals.iodine.value', 'values', c."minerals.iodine.value"),
        ('minerals.magnesium.value', 'values', c."minerals.magnesium.value"),
        ('minerals.manganese.value', 'values', c."minerals.manganese.value"),
        ('minerals.phosphorous.value', 'values', c."minerals.phosphorous.value"),
        ('minerals.selenium.value', 'values', c."minerals.selenium.value"),
        ('minerals.sodium.value', 'values', c."minerals.sodium.value"),
        ('moisture.value', 'values', c."moisture.value"),
        ('proteins.crude_protein.value', 'values', c."proteins.crude_protein.value"),
        ('trace_elements.copper.value', 'values', c."trace_elements.copper.value"),
        ('trace_elements.copper_sulfate.value', 'values', c."trace_elements.copper_sulfate.value"),
        ('trace_elements.iron.value', 'values', c."trace_elements.iron.value"),
        ('trace_elements.zinc.value', 'values', c."trace_elements.zinc.value"),
        ('vitamins..b1_vitamin.value', 'values', c."vitamins..b1_vitamin.value"),
        ('vitamins.a_vitamin.value', 'values', c."vitamins.a_vitamin.value"),
        ('vitamins.b12_vitamin.value', 'values', c."vitamins.b12_vitamin.value"),
        ('vitamins.b2_vitamin.value', 'values', c."vitamins.b2_vitamin.value"),
        ('vitamins.b6_vitamin.value', 'values', c."vitamins.b6_vitamin.value"),
        ('vitamins.biotin.value', 'values', c."vitamins.biotin.value"),
        ('vitamins.d3_vitamin.value', 'values', c."vitamins.d3_vitamin.value"),
        ('vitamins.e_vitamin.value', 'values', c."vitamins.e_vitamin.value"),
        ('vitamins.folic_acid.value', 'values', c."vitamins.folic_acid.value"),
        ('vitamins.niacin.value', 'values', c."vitamins.niacin.value"),
        ('vitamins.pantothenic_acid.value', 'values', c."vitamins.pantothenic_acid.value"),
        ('product_content', 'text', c."product_content"),
        ('product_additives', 'text', c."product_additives"),
        ('product_carbohydrates_source', 'text', c."product_carbohydrates_source"),
        ('product_name_en', 'text', c."product_name_en"),
        ('product_category', 'category_type', c."product_category"),
        ('product_type', 'category_type', c."product_type")
) AS v(column_name, correction_group, value_text)
GROUP BY v.correction_group, v.column_name ORDER BY v.correction_group, v.column_name;

DO $validation$
BEGIN
    IF EXISTS (
        SELECT 1 FROM vet_analytics.vet_clean AS c
        CROSS JOIN LATERAL (VALUES
        ('aminoacids.lysine.value', c."aminoacids.lysine.value"),
        ('convertible_energy.value', c."convertible_energy.value"),
        ('minerals.calsium.value', c."minerals.calsium.value"),
        ('minerals.iodine.value', c."minerals.iodine.value"),
        ('minerals.magnesium.value', c."minerals.magnesium.value"),
        ('minerals.manganese.value', c."minerals.manganese.value"),
        ('minerals.phosphorous.value', c."minerals.phosphorous.value"),
        ('minerals.selenium.value', c."minerals.selenium.value"),
        ('minerals.sodium.value', c."minerals.sodium.value"),
        ('moisture.value', c."moisture.value"),
        ('proteins.crude_protein.value', c."proteins.crude_protein.value"),
        ('trace_elements.copper.value', c."trace_elements.copper.value"),
        ('trace_elements.copper_sulfate.value', c."trace_elements.copper_sulfate.value"),
        ('trace_elements.iron.value', c."trace_elements.iron.value"),
        ('trace_elements.zinc.value', c."trace_elements.zinc.value"),
        ('vitamins..b1_vitamin.value', c."vitamins..b1_vitamin.value"),
        ('vitamins.a_vitamin.value', c."vitamins.a_vitamin.value"),
        ('vitamins.b12_vitamin.value', c."vitamins.b12_vitamin.value"),
        ('vitamins.b2_vitamin.value', c."vitamins.b2_vitamin.value"),
        ('vitamins.b6_vitamin.value', c."vitamins.b6_vitamin.value"),
        ('vitamins.biotin.value', c."vitamins.biotin.value"),
        ('vitamins.d3_vitamin.value', c."vitamins.d3_vitamin.value"),
        ('vitamins.e_vitamin.value', c."vitamins.e_vitamin.value"),
        ('vitamins.folic_acid.value', c."vitamins.folic_acid.value"),
        ('vitamins.niacin.value', c."vitamins.niacin.value"),
        ('vitamins.pantothenic_acid.value', c."vitamins.pantothenic_acid.value"),
        ('product_content', c."product_content"),
        ('product_additives', c."product_additives"),
        ('product_carbohydrates_source', c."product_carbohydrates_source"),
        ('product_name_en', c."product_name_en"),
        ('product_category', c."product_category"),
        ('product_type', c."product_type")
        ) AS v(column_name, value_text)
        WHERE v.value_text ~ '[0-9][.][.][0-9]'
    ) THEN
        RAISE EXCEPTION 'Post-check failed for the double-dot target columns';
    END IF;
END;
$validation$;

-- 4. Before/after results for this run, including successfully corrected cells.
SELECT e.product_id, e.product_name, e.column_name,
       e.value_before, v.value_text AS value_after
FROM tmp_vetsy_double_dots_before AS e
JOIN vet_analytics.vet_clean AS c ON c._id = e.product_id
CROSS JOIN LATERAL (VALUES
        ('aminoacids.lysine.value', c."aminoacids.lysine.value"),
        ('convertible_energy.value', c."convertible_energy.value"),
        ('minerals.calsium.value', c."minerals.calsium.value"),
        ('minerals.iodine.value', c."minerals.iodine.value"),
        ('minerals.magnesium.value', c."minerals.magnesium.value"),
        ('minerals.manganese.value', c."minerals.manganese.value"),
        ('minerals.phosphorous.value', c."minerals.phosphorous.value"),
        ('minerals.selenium.value', c."minerals.selenium.value"),
        ('minerals.sodium.value', c."minerals.sodium.value"),
        ('moisture.value', c."moisture.value"),
        ('proteins.crude_protein.value', c."proteins.crude_protein.value"),
        ('trace_elements.copper.value', c."trace_elements.copper.value"),
        ('trace_elements.copper_sulfate.value', c."trace_elements.copper_sulfate.value"),
        ('trace_elements.iron.value', c."trace_elements.iron.value"),
        ('trace_elements.zinc.value', c."trace_elements.zinc.value"),
        ('vitamins..b1_vitamin.value', c."vitamins..b1_vitamin.value"),
        ('vitamins.a_vitamin.value', c."vitamins.a_vitamin.value"),
        ('vitamins.b12_vitamin.value', c."vitamins.b12_vitamin.value"),
        ('vitamins.b2_vitamin.value', c."vitamins.b2_vitamin.value"),
        ('vitamins.b6_vitamin.value', c."vitamins.b6_vitamin.value"),
        ('vitamins.biotin.value', c."vitamins.biotin.value"),
        ('vitamins.d3_vitamin.value', c."vitamins.d3_vitamin.value"),
        ('vitamins.e_vitamin.value', c."vitamins.e_vitamin.value"),
        ('vitamins.folic_acid.value', c."vitamins.folic_acid.value"),
        ('vitamins.niacin.value', c."vitamins.niacin.value"),
        ('vitamins.pantothenic_acid.value', c."vitamins.pantothenic_acid.value"),
        ('product_content', c."product_content"),
        ('product_additives', c."product_additives"),
        ('product_carbohydrates_source', c."product_carbohydrates_source"),
        ('product_name_en', c."product_name_en"),
        ('product_category', c."product_category"),
        ('product_type', c."product_type")
) AS v(column_name, value_text)
WHERE v.column_name = e.column_name
ORDER BY e.column_name, e.product_id;

COMMIT;
