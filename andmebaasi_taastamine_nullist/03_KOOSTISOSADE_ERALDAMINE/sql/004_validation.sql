-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 03_KOOSTISOSADE_ERALDAMINE | VERSIOON: 2026-10-05
-- AUTORLUS: Astriti eraldamise taastamist toetav kontrollskript.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- ING-02: Read-only checks after a successful Python commit.
-- Compare ingredient_rows with Python's final saved-row count.
SELECT count(*) AS ingredient_rows, count(DISTINCT _id) AS products_with_ingredients,
       count(DISTINCT ingredient) AS distinct_ingredients
FROM vet_analytics.product_ingredients_rows;

-- Output contract: these four columns in this order.
SELECT column_name, data_type, ordinal_position
FROM information_schema.columns
WHERE table_schema = 'vet_analytics' AND table_name = 'product_ingredients_rows'
ORDER BY ordinal_position;

-- Expected: no rows. An ID must exist in the product source.
SELECT DISTINCT i._id
FROM vet_analytics.product_ingredients_rows i
LEFT JOIN vet_analytics.vet_clean_mg_kg p ON p._id::text = i._id::text
WHERE p._id IS NULL;

-- Expected: zero blank IDs and zero blank ingredient names.
SELECT count(*) FILTER (WHERE NULLIF(btrim(_id::text), '') IS NULL) AS blank_ids,
       count(*) FILTER (WHERE NULLIF(btrim(ingredient), '') IS NULL) AS blank_ingredients
FROM vet_analytics.product_ingredients_rows;

-- Expected: no rows. One ingredient should occur once within a product.
SELECT _id, ingredient, count(*) AS occurrences
FROM vet_analytics.product_ingredients_rows
GROUP BY _id, ingredient HAVING count(*) > 1;

-- These products need inspection; absence of ingredients is not automatically an error.
SELECT p._id, p.product_name_fi, p.product_name_en, p.product_content
FROM vet_analytics.vet_clean_mg_kg p
WHERE NOT EXISTS (
    SELECT 1 FROM vet_analytics.product_ingredients_rows i
    WHERE i._id::text = p._id::text
)
ORDER BY p._id LIMIT 20;

-- Inspect sample cleaned ingredient rows against the original descriptions.
SELECT i._id, i.product_name_fi, i.ingredient, p.product_content
FROM vet_analytics.product_ingredients_rows i
JOIN vet_analytics.vet_clean_mg_kg p ON p._id::text = i._id::text
ORDER BY i._id, i.ingredient LIMIT 30;
