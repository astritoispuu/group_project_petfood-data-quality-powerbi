-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 04_KOOSTISOSADE_KATEGORISEERIMINE | VERSIOON: 2026-10-05
-- AUTORLUS: Liina töövoog; taastamise kontroll-/struktuurifail.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- SCRIPT: 03_validation.sql
-- STEP ID: CAT_STEP_03
-- PURPOSE: Kontrolli salvestatud tulemust ja võrdlustabeli katvust
-- INPUT: vet_analytics.product_ingredients_rows; vet_analytics.ingredients_categories_reference; vet_powerbi.fact_ingredients
-- OUTPUT: Ainult päringutulemused
-- PREREQUISITES: README.md
-- VALIDATION: 03_validation.sql
-- EXECUTION LOG: EXECUTION_LOG.md
-- EXECUTION STATUS: NOT_RUN
-- ORIGINAL WORK: Liina töövoogu täiendav kontroll-/taastamisskript, lisatud 05.10.2026
-- REVISION: 2026-10-05
-- SOURCE POLICY: Sisendtabelid säilivad
-- RUN POLICY: README.md

-- Mahud ei pea võrduma: osa sisendeid ei saa vastet. CSV-l on 6759 rida.
SELECT 'input' AS object, COUNT(*) AS row_count FROM vet_analytics.product_ingredients_rows
UNION ALL
SELECT 'reference', COUNT(*) FROM vet_analytics.ingredients_categories_reference
UNION ALL
SELECT 'output', COUNT(*) FROM vet_powerbi.fact_ingredients;
-- Nõutud võtmed, koostisosad ja kategooriad: kõik vigade arvud peaksid olema 0.
SELECT
    COUNT(*) FILTER (WHERE NULLIF(BTRIM(product_id), '') IS NULL) AS empty_product_ids,
    COUNT(*) FILTER (WHERE NULLIF(BTRIM(ingredient), '') IS NULL) AS empty_ingredients,
    COUNT(*) FILTER (WHERE NULLIF(BTRIM(category), '') IS NULL) AS empty_categories
FROM vet_powerbi.fact_ingredients;
-- Tundmatute toote-koostisosa paaride päring peab tagastama 0 rida.
SELECT f.product_id, f.ingredient
FROM vet_powerbi.fact_ingredients AS f
WHERE NOT EXISTS (
    SELECT 1 FROM vet_analytics.product_ingredients_rows AS s
    WHERE s."_id"::text = f.product_id AND s.ingredient = f.ingredient
);
-- Kordused on ülevaatuseks: kood ei eemalda sisendduplikaate.
SELECT product_id, ingredient, COUNT(*) AS occurrences
FROM vet_powerbi.fact_ingredients
GROUP BY product_id, ingredient HAVING COUNT(*) > 1;
-- Vaata kategooriate ja lippude jaotust; Review väärtusi ei muudeta automaatselt.
SELECT category, COUNT(*) AS row_count
FROM vet_powerbi.fact_ingredients GROUP BY category ORDER BY row_count DESC;
SELECT protein, oil, carbs, COUNT(*) AS row_count
FROM vet_powerbi.fact_ingredients GROUP BY protein, oil, carbs ORDER BY row_count DESC;
-- Kategooriata ja käsitsi kontrolli vajavad võrdlusread vajavad sisulist ülevaatust.
SELECT
    COUNT(*) AS reference_rows,
    COUNT(*) FILTER (WHERE NULLIF(BTRIM("Category"), '') IS NULL) AS missing_categories,
    COUNT(*) FILTER (WHERE "Human Review" = 'Yes') AS human_review_rows
FROM vet_analytics.ingredients_categories_reference;
