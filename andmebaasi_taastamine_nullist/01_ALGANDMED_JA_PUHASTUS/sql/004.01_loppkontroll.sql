-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 01_ALGANDMED_JA_PUHASTUS | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Fail: 004.01_loppkontroll.sql
-- Etapp: 06 | Uuendatud: 05.10.2026
-- Eesmärk: Kontrollib põhitabelite mahu, struktuuri ja kinnitatud paranduste tulemusi.
-- Eeldus: Kõik eelnevad viis põhifaili on edukalt läbitud.
-- Tulemus: Kontrolltulemused vastavad README tabelile; audititabeleid pole vaja.
-- Muudab: Ei muuda andmeid ega loo püsivaid objekte; ainult SELECT-päringud.
-- Kasutamine: ava sama sihtbaasi ühenduses ja käivita kogu fail (Alt+X).
-- Vea korral peatu; avatud tehingus tee ROLLBACK ja kõrvalda põhjus.
-- Täpne järjekord ja tulemuste tõlgendus: juurkausta README.md.

-- 1. Põhitabelite read ja võtmed. Mõlemal tabelil 15 202 rida/eri ID-d.
SELECT 'vet_raw' AS tabel, count(*) AS ridu, count(DISTINCT _id) AS eri_id,
       count(*) FILTER (WHERE NULLIF(btrim(_id), '') IS NULL) AS puuduvaid_id
FROM vet_analytics.vet_raw
UNION ALL
SELECT 'vet_clean', count(*), count(DISTINCT _id),
       count(*) FILTER (WHERE NULLIF(btrim(_id), '') IS NULL)
FROM vet_analytics.vet_clean;

-- Mõlemas suunas peab puuduvaid ID-sid olema 0.
SELECT count(*) FILTER (WHERE c._id IS NULL) AS cleanist_puuduvaid_id,
       count(*) FILTER (WHERE r._id IS NULL) AS rawst_puuduvaid_id
FROM vet_analytics.vet_raw AS r
FULL JOIN vet_analytics.vet_clean AS c ON c._id = r._id;

-- 2. Veergude arv ja tüübid: kummaski 215 TEXT veergu.
SELECT table_name, count(*) AS veerge,
       count(*) FILTER (WHERE data_type <> 'text') AS mitte_text_veerge
FROM information_schema.columns
WHERE table_schema = 'vet_analytics' AND table_name IN ('vet_raw', 'vet_clean')
GROUP BY table_name ORDER BY table_name;

-- Struktuur peab vastama nime, järjekorra ja tüübi poolest; oodatav 0.
WITH r AS (
    SELECT column_name, ordinal_position, data_type
    FROM information_schema.columns
    WHERE table_schema = 'vet_analytics' AND table_name = 'vet_raw'
), c AS (
    SELECT column_name, ordinal_position, data_type
    FROM information_schema.columns
    WHERE table_schema = 'vet_analytics' AND table_name = 'vet_clean'
)
SELECT count(*) AS struktuurierinevusi
FROM r FULL JOIN c USING (column_name)
WHERE r.ordinal_position IS DISTINCT FROM c.ordinal_position
   OR r.data_type IS DISTINCT FROM c.data_type;

-- Unikaalne ID indeks peab olemas olema; päring tagastab ühe rea.
SELECT indexname, indexdef FROM pg_indexes
WHERE schemaname = 'vet_analytics' AND tablename = 'vet_clean'
  AND indexname = 'vet_clean_id_uq';

-- 3. Kogu rea andmetes otsime kinnitatud number..number mustrit; oodatav 0.
SELECT count(*) FILTER (WHERE c::text ~ '[0-9][.][.][0-9]') AS number_topeltpunkt_number_ridu
FROM vet_analytics.vet_clean AS c;

-- Vabateksti '..' esinemine ei tähenda automaatselt viga.
-- Seda näitajat ei nõuta nulliks; allesjäänud näiteid tuleb hinnata eraldi.
SELECT count(*) FILTER (WHERE c::text LIKE '%..%') AS muu_topeltpunktiga_ridu
FROM vet_analytics.vet_clean AS c;

SELECT c._id, c.product_name_fi,
       substring(c::text FROM '.{0,50}[.][.].{0,50}') AS topeltpunkti_umbrus
FROM vet_analytics.vet_clean AS c
WHERE c::text LIKE '%..%' ORDER BY c._id LIMIT 30;

-- 4. Nihke sihtrühma lõppkontroll. LEFT JOIN jätab nähtavale ka puuduva toote.
WITH sihtread AS (
SELECT 'mangaan'::text AS toitaine, r._id,
       r."minerals.manganese.unit" AS algne_arv_uhiku_valjas,
       replace(r."minerals.manganese.unit", '..', '.') AS oodatav_vaartus
FROM vet_analytics.vet_raw AS r
WHERE r."minerals.manganese.value" = '0'
  AND r."minerals..manganese.unit.1" = 'mg'
  AND NULLIF(btrim(r."minerals.manganese.unit"), '') IS NOT NULL
  AND btrim(r."minerals.manganese.unit") <> 'mg'
UNION ALL
SELECT 'raud', r._id, r."trace_elements.iron.unit", '20'
FROM vet_analytics.vet_raw AS r WHERE r._id = '691ce762f28d412bf11f0c46'
UNION ALL
SELECT 'jood', r._id, r."minerals.iodine.unit", '0.71'
FROM vet_analytics.vet_raw AS r WHERE r._id = '691ce762f28d412bf11f0c22'
), praegune AS (
SELECT s.*,
       c._id AS leitud_id,
       CASE s.toitaine
           WHEN 'mangaan' THEN c."minerals.manganese.value"
           WHEN 'raud' THEN c."trace_elements.iron.value"
           ELSE c."minerals.iodine.value"
       END AS praegune_vaartus,
       CASE s.toitaine
           WHEN 'mangaan' THEN c."minerals.manganese.unit"
           WHEN 'raud' THEN c."trace_elements.iron.unit"
           ELSE c."minerals.iodine.unit"
       END AS praegune_uhik
FROM sihtread AS s
LEFT JOIN vet_analytics.vet_clean AS c ON c._id = s._id
)
SELECT toitaine, count(*) AS algselt_nihkes_ridu,
       count(*) FILTER (WHERE NOT (leitud_id IS NULL OR praegune_uhik IS DISTINCT FROM 'mg' OR praegune_vaartus IS DISTINCT FROM oodatav_vaartus)) AS korras_ridu,
       count(*) FILTER (WHERE leitud_id IS NULL OR praegune_uhik IS DISTINCT FROM 'mg' OR praegune_vaartus IS DISTINCT FROM oodatav_vaartus) AS veel_vigaseid_ridu,
       min(_id) FILTER (WHERE leitud_id IS NULL OR praegune_uhik IS DISTINCT FROM 'mg' OR praegune_vaartus IS DISTINCT FROM oodatav_vaartus) AS naidis_vigase_rea_id
FROM praegune GROUP BY toitaine ORDER BY toitaine;

-- 5. Viis teadaolevat näiterida. Puuduv toode jääb tulemusse NULL väärtustega.
WITH sihtread(toitaine, _id) AS (
    VALUES
        ('mangaan', '67441cded15392af62f791c5'),
        ('mangaan', '67441cded15392af62f7924b'),
        ('mangaan', '67441cded15392af62f793f7'),
        ('raud',    '691ce762f28d412bf11f0c46'),
        ('jood',    '691ce762f28d412bf11f0c22')
)
SELECT s.toitaine, s._id, c.product_name_fi,
       CASE s.toitaine
           WHEN 'mangaan' THEN r."minerals.manganese.value"
           WHEN 'raud' THEN r."trace_elements.iron.value"
           ELSE r."minerals.iodine.value"
       END AS algne_value,
       CASE s.toitaine
           WHEN 'mangaan' THEN r."minerals.manganese.unit"
           WHEN 'raud' THEN r."trace_elements.iron.unit"
           ELSE r."minerals.iodine.unit"
       END AS algne_unit,
       CASE s.toitaine
           WHEN 'mangaan' THEN c."minerals.manganese.value"
           WHEN 'raud' THEN c."trace_elements.iron.value"
           ELSE c."minerals.iodine.value"
       END AS uus_value,
       CASE s.toitaine
           WHEN 'mangaan' THEN c."minerals.manganese.unit"
           WHEN 'raud' THEN c."trace_elements.iron.unit"
           ELSE c."minerals.iodine.unit"
       END AS uus_unit
FROM sihtread AS s
LEFT JOIN vet_analytics.vet_raw AS r ON r._id = s._id
LEFT JOIN vet_analytics.vet_clean AS c ON c._id = s._id
ORDER BY s.toitaine, s._id;

-- 6. Tootenimede olemasolu. COUNT FILTER loendab ainult vastava tingimuse read.
-- See kontroll ei täida ega muuda vet_clean nimesid.
SELECT count(*) AS tooteid_kokku,
       count(*) FILTER (WHERE NULLIF(btrim(product_name_fi), '') IS NULL)
           AS soome_nimi_puudub,
       count(*) FILTER (WHERE NULLIF(btrim(product_name_fi), '') IS NULL
                          AND NULLIF(btrim(product_name_en), '') IS NOT NULL)
           AS fi_puudub_en_olemas,
       count(*) FILTER (WHERE NULLIF(btrim(product_name_fi), '') IS NULL
                          AND NULLIF(btrim(product_name_en), '') IS NULL)
           AS molemad_nimed_puuduvad
FROM vet_analytics.vet_clean;
