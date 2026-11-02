-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 01_ALGANDMED_JA_PUHASTUS | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Fail: 002.09_topeltpunktide_leidmine_parandamine.sql
-- Etapp: 04 | Uuendatud: 05.10.2026
-- Eesmärk: Leiab ja parandab number..number vead 32 kinnitatud veerus.
-- Eeldus: vet_raw ja vet_clean on loodud ning import kontrollitud.
-- Tulemus: 32 sihtveerus ei ole number..number vigu. Mangaani ühikuväli parandatakse järgmises etapis.
-- Muudab: Muudab vet_clean lahtrite sisu; vet_raw, veerupäised ja sihtloendivälised veerud säilivad.
-- Kasutamine: ava sama sihtbaasi ühenduses ja käivita kogu fail (Alt+X).
-- Vea korral peatu; avatud tehingus tee ROLLBACK ja kõrvalda põhjus.
-- Täpne järjekord ja tulemuste tõlgendus: juurkausta README.md.

BEGIN;

-- 1. Eelkontroll otse vet_clean tabelist; püsivaid audititabeleid pole vaja.
-- Üks kirje tähendab ühte vigast lahtrit, mitte tingimata ühte eri toodet.
CREATE TEMP TABLE tmp_vetsy_topeltpunktid_enne ON COMMIT DROP AS
SELECT c._id AS product_id,
       COALESCE(NULLIF(btrim(c.product_name_fi), ''),
                NULLIF(btrim(c.product_name_en), '')) AS product_name,
       v.veerg, v.ryhm, v.vaartus AS vaartus_enne
FROM vet_analytics.vet_clean AS c
CROSS JOIN LATERAL (VALUES
        ('aminoacids.lysine.value', 'vaartused', c."aminoacids.lysine.value"),
        ('convertible_energy.value', 'vaartused', c."convertible_energy.value"),
        ('minerals.calsium.value', 'vaartused', c."minerals.calsium.value"),
        ('minerals.iodine.value', 'vaartused', c."minerals.iodine.value"),
        ('minerals.magnesium.value', 'vaartused', c."minerals.magnesium.value"),
        ('minerals.manganese.value', 'vaartused', c."minerals.manganese.value"),
        ('minerals.phosphorous.value', 'vaartused', c."minerals.phosphorous.value"),
        ('minerals.selenium.value', 'vaartused', c."minerals.selenium.value"),
        ('minerals.sodium.value', 'vaartused', c."minerals.sodium.value"),
        ('moisture.value', 'vaartused', c."moisture.value"),
        ('proteins.crude_protein.value', 'vaartused', c."proteins.crude_protein.value"),
        ('trace_elements.copper.value', 'vaartused', c."trace_elements.copper.value"),
        ('trace_elements.copper_sulfate.value', 'vaartused', c."trace_elements.copper_sulfate.value"),
        ('trace_elements.iron.value', 'vaartused', c."trace_elements.iron.value"),
        ('trace_elements.zinc.value', 'vaartused', c."trace_elements.zinc.value"),
        ('vitamins..b1_vitamin.value', 'vaartused', c."vitamins..b1_vitamin.value"),
        ('vitamins.a_vitamin.value', 'vaartused', c."vitamins.a_vitamin.value"),
        ('vitamins.b12_vitamin.value', 'vaartused', c."vitamins.b12_vitamin.value"),
        ('vitamins.b2_vitamin.value', 'vaartused', c."vitamins.b2_vitamin.value"),
        ('vitamins.b6_vitamin.value', 'vaartused', c."vitamins.b6_vitamin.value"),
        ('vitamins.biotin.value', 'vaartused', c."vitamins.biotin.value"),
        ('vitamins.d3_vitamin.value', 'vaartused', c."vitamins.d3_vitamin.value"),
        ('vitamins.e_vitamin.value', 'vaartused', c."vitamins.e_vitamin.value"),
        ('vitamins.folic_acid.value', 'vaartused', c."vitamins.folic_acid.value"),
        ('vitamins.niacin.value', 'vaartused', c."vitamins.niacin.value"),
        ('vitamins.pantothenic_acid.value', 'vaartused', c."vitamins.pantothenic_acid.value"),
        ('product_content', 'tekst', c."product_content"),
        ('product_additives', 'tekst', c."product_additives"),
        ('product_carbohydrates_source', 'tekst', c."product_carbohydrates_source"),
        ('product_name_en', 'tekst', c."product_name_en"),
        ('product_category', 'kategooria_tyyp', c."product_category"),
        ('product_type', 'kategooria_tyyp', c."product_type")
) AS v(veerg, ryhm, vaartus)
WHERE v.vaartus ~ '[0-9][.][.][0-9]';

SELECT ryhm, veerg, count(*) AS vigaseid_lahtrid_enne
FROM tmp_vetsy_topeltpunktid_enne
GROUP BY ryhm, veerg ORDER BY ryhm, veerg;

-- 2. Parandused. Kaks punkti asendatakse ühega ainult numbrite vahel.
-- Ettevaate/tagasivaate muster parandab ka 1..2..3 -> 1.2.3 ühe käiguga.
-- See parandab kirjapilti; ei muuda teksti automaatselt numeric tüübiks.
-- Muudame ainult kinnitatud vaartused veerge ja ainult mustriga ridu.
WITH muudetud AS (
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
SELECT 'vaartused' AS paranduste_ryhm, count(*) AS muudetud_ridu FROM muudetud;

-- Muudame ainult kinnitatud tekst veerge ja ainult mustriga ridu.
WITH muudetud AS (
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
SELECT 'tekst' AS paranduste_ryhm, count(*) AS muudetud_ridu FROM muudetud;

-- Muudame ainult kinnitatud kategooria_tyyp veerge ja ainult mustriga ridu.
WITH muudetud AS (
    UPDATE vet_analytics.vet_clean AS c
    SET
    "product_category" = regexp_replace("product_category", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g'),
    "product_type" = regexp_replace("product_type", '(?<=[0-9])[.][.](?=[0-9])', '.', 'g')
    WHERE c."product_category" ~ '[0-9][.][.][0-9]'
   OR c."product_type" ~ '[0-9][.][.][0-9]'
    RETURNING _id
)
SELECT 'kategooria_tyyp' AS paranduste_ryhm, count(*) AS muudetud_ridu FROM muudetud;


-- 3. Järelkontroll täpselt samade 32 veeru kohta; oodatav igal real 0.
SELECT v.ryhm, v.veerg,
       count(*) FILTER (WHERE v.vaartus ~ '[0-9][.][.][0-9]') AS alles_vigaseid_lahtrid
FROM vet_analytics.vet_clean AS c
CROSS JOIN LATERAL (VALUES
        ('aminoacids.lysine.value', 'vaartused', c."aminoacids.lysine.value"),
        ('convertible_energy.value', 'vaartused', c."convertible_energy.value"),
        ('minerals.calsium.value', 'vaartused', c."minerals.calsium.value"),
        ('minerals.iodine.value', 'vaartused', c."minerals.iodine.value"),
        ('minerals.magnesium.value', 'vaartused', c."minerals.magnesium.value"),
        ('minerals.manganese.value', 'vaartused', c."minerals.manganese.value"),
        ('minerals.phosphorous.value', 'vaartused', c."minerals.phosphorous.value"),
        ('minerals.selenium.value', 'vaartused', c."minerals.selenium.value"),
        ('minerals.sodium.value', 'vaartused', c."minerals.sodium.value"),
        ('moisture.value', 'vaartused', c."moisture.value"),
        ('proteins.crude_protein.value', 'vaartused', c."proteins.crude_protein.value"),
        ('trace_elements.copper.value', 'vaartused', c."trace_elements.copper.value"),
        ('trace_elements.copper_sulfate.value', 'vaartused', c."trace_elements.copper_sulfate.value"),
        ('trace_elements.iron.value', 'vaartused', c."trace_elements.iron.value"),
        ('trace_elements.zinc.value', 'vaartused', c."trace_elements.zinc.value"),
        ('vitamins..b1_vitamin.value', 'vaartused', c."vitamins..b1_vitamin.value"),
        ('vitamins.a_vitamin.value', 'vaartused', c."vitamins.a_vitamin.value"),
        ('vitamins.b12_vitamin.value', 'vaartused', c."vitamins.b12_vitamin.value"),
        ('vitamins.b2_vitamin.value', 'vaartused', c."vitamins.b2_vitamin.value"),
        ('vitamins.b6_vitamin.value', 'vaartused', c."vitamins.b6_vitamin.value"),
        ('vitamins.biotin.value', 'vaartused', c."vitamins.biotin.value"),
        ('vitamins.d3_vitamin.value', 'vaartused', c."vitamins.d3_vitamin.value"),
        ('vitamins.e_vitamin.value', 'vaartused', c."vitamins.e_vitamin.value"),
        ('vitamins.folic_acid.value', 'vaartused', c."vitamins.folic_acid.value"),
        ('vitamins.niacin.value', 'vaartused', c."vitamins.niacin.value"),
        ('vitamins.pantothenic_acid.value', 'vaartused', c."vitamins.pantothenic_acid.value"),
        ('product_content', 'tekst', c."product_content"),
        ('product_additives', 'tekst', c."product_additives"),
        ('product_carbohydrates_source', 'tekst', c."product_carbohydrates_source"),
        ('product_name_en', 'tekst', c."product_name_en"),
        ('product_category', 'kategooria_tyyp', c."product_category"),
        ('product_type', 'kategooria_tyyp', c."product_type")
) AS v(veerg, ryhm, vaartus)
GROUP BY v.ryhm, v.veerg ORDER BY v.ryhm, v.veerg;

DO $kontroll$
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
        ) AS v(veerg, vaartus)
        WHERE v.vaartus ~ '[0-9][.][.][0-9]'
    ) THEN
        RAISE EXCEPTION 'Topeltpunktide sihtveergude järelkontroll ebaõnnestus';
    END IF;
END;
$kontroll$;

-- 4. Selle käivituse enne/pärast tulemused, ka edukalt parandatud lahtrid.
SELECT e.product_id, e.product_name, e.veerg,
       e.vaartus_enne, v.vaartus AS vaartus_parast
FROM tmp_vetsy_topeltpunktid_enne AS e
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
) AS v(veerg, vaartus)
WHERE v.veerg = e.veerg
ORDER BY e.veerg, e.product_id;

COMMIT;
