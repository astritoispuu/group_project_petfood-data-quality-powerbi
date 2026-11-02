-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 04_KOOSTISOSADE_KATEGORISEERIMINE | VERSIOON: 2026-10-05
-- AUTORLUS: Liina töövoog; taastamise kontroll-/struktuurifail.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- SCRIPT: 03_validation.sql
-- STEP ID: CAT_STEP_03
-- PURPOSE: Review committed output and reference coverage
-- INPUT: vet_analytics.product_ingredients_rows; vet_analytics.ingredients_categories_reference; vet_powerbi.fact_ingredients
-- OUTPUT: Query results only
-- PREREQUISITES: README.md
-- VALIDATION: 03_validation.sql
-- EXECUTION LOG: EXECUTION_LOG.md
-- EXECUTION STATUS: NOT_RUN
-- ORIGINAL WORK: Supplementary validation/restoration script for Liina's workflow, added 2026-10-05
-- REVISION: 2026-10-05
-- SOURCE POLICY: Source tables are preserved
-- RUN POLICY: README.md

-- Counts need not match: some inputs have no match. The supplied CSV has 6759 rows.
SELECT 'input' AS object, COUNT(*) AS row_count FROM vet_analytics.product_ingredients_rows
UNION ALL
SELECT 'reference', COUNT(*) FROM vet_analytics.ingredients_categories_reference
UNION ALL
SELECT 'output', COUNT(*) FROM vet_powerbi.fact_ingredients;
-- Required keys, ingredients and categories: every error count should be 0.
SELECT
    COUNT(*) FILTER (WHERE NULLIF(BTRIM(product_id), '') IS NULL) AS empty_product_ids,
    COUNT(*) FILTER (WHERE NULLIF(BTRIM(ingredient), '') IS NULL) AS empty_ingredients,
    COUNT(*) FILTER (WHERE NULLIF(BTRIM(category), '') IS NULL) AS empty_categories
FROM vet_powerbi.fact_ingredients;
-- Unknown product-ingredient pairs: this query should return 0 rows.
SELECT f.product_id, f.ingredient
FROM vet_powerbi.fact_ingredients AS f
WHERE NOT EXISTS (
    SELECT 1 FROM vet_analytics.product_ingredients_rows AS s
    WHERE s."_id"::text = f.product_id AND s.ingredient = f.ingredient
);
-- Review duplicates: the script does not deduplicate input rows.
SELECT product_id, ingredient, COUNT(*) AS occurrences
FROM vet_powerbi.fact_ingredients
GROUP BY product_id, ingredient HAVING COUNT(*) > 1;
-- Review category and flag distributions; Review values are not changed automatically.
SELECT category, COUNT(*) AS row_count
FROM vet_powerbi.fact_ingredients GROUP BY category ORDER BY row_count DESC;
SELECT protein, oil, carbs, COUNT(*) AS row_count
FROM vet_powerbi.fact_ingredients GROUP BY protein, oil, carbs ORDER BY row_count DESC;
-- Reference rows without categories or needing human review require content review.
SELECT
    COUNT(*) AS reference_rows,
    COUNT(*) FILTER (WHERE NULLIF(BTRIM("Category"), '') IS NULL) AS missing_categories,
    COUNT(*) FILTER (WHERE "Human Review" = 'Yes') AS human_review_rows
FROM vet_analytics.ingredients_categories_reference;
