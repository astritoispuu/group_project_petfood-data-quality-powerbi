-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 03_KOOSTISOSADE_ERALDAMINE | VERSIOON: 2026-10-05
-- AUTORLUS: Astriti eraldamise taastamist toetav kontrollskript.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- ING-01: Read-only preflight. Run after creating vet_clean_mg_kg.
-- Both checks should return a non-NULL source and all four column names.
SELECT to_regclass('vet_analytics.vet_clean_mg_kg') AS source_table;
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'vet_analytics'
  AND table_name = 'vet_clean_mg_kg'
  AND column_name IN ('_id', 'product_name_fi', 'product_name_en', 'product_content')
ORDER BY ordinal_position;

-- Source rows are products; output rows will be ingredients.
-- Empty product descriptions are allowed but cannot produce ingredients.
SELECT count(*) AS source_products,
       count(*) FILTER (WHERE NULLIF(btrim(product_content::text), '') IS NULL)
           AS products_without_content,
       count(*) FILTER (WHERE NULLIF(btrim(_id::text), '') IS NULL)
           AS missing_product_ids
FROM vet_analytics.vet_clean_mg_kg;

-- Expected: no rows. Review duplicate product IDs before extraction.
SELECT _id, count(*) AS occurrences
FROM vet_analytics.vet_clean_mg_kg
GROUP BY _id HAVING count(*) > 1;
