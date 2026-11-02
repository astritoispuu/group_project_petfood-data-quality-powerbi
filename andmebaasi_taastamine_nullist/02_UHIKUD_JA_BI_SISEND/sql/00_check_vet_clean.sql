-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 02_UHIKUD_JA_BI_SISEND | VERSIOON: 2026-10-05
-- AUTORLUS: Oksana – algne normaliseerimisloogika ja vastendused.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Original normalization logic and nutrient mappings: Oksana.
-- Compatibility review and documentation: 2026-10-05.
-- Read-only inventory. Run before the creation scripts.
-- This package starts from an existing, cleaned vet_clean table.
SELECT current_database() AS database_name,
       to_regclass('vet_analytics.vet_clean') AS source_table;

-- Export this result if the creation script reports missing columns.
SELECT ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'vet_analytics' AND table_name = 'vet_clean'
ORDER BY ordinal_position;

-- Match row counts to the current source, not a hard-coded historical count.
SELECT count(*) AS source_rows FROM vet_analytics.vet_clean;

-- Inspect empty and duplicate product identifiers before creating BI relations.
SELECT count(*) AS empty_product_ids
FROM vet_analytics.vet_clean
WHERE NULLIF(btrim(_id::text), '') IS NULL;

SELECT _id, count(*) AS occurrences
FROM vet_analytics.vet_clean
GROUP BY _id
HAVING count(*) > 1
ORDER BY occurrences DESC
LIMIT 20;
