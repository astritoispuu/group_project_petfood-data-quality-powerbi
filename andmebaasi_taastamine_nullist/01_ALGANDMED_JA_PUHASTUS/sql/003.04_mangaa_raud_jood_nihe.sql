-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 01_ALGANDMED_JA_PUHASTUS | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Fail: 003.04_mangaa_raud_jood_nihe.sql
-- Etapp: 05 | Uuendatud: 05.10.2026
-- Eesmärk: Parandab mangaani arvuteksti ning kinnitatud Mn/Fe/I nihked.
-- Eeldus: Etapid 01–04 on läbitud; kasutatakse sama algset CSV-d.
-- Tulemus: Algallika järgi mangaan 378, raud 1 ja jood 1 rida on õigetes väärtuse/ühiku väljades.
-- Muudab: Muudab üksnes vet_clean kinnitatud toitainevälju; ühikureeglite tabelit ei kasuta.
-- Kasutamine: ava sama sihtbaasi ühenduses ja käivita kogu fail (Alt+X).
-- Vea korral peatu; avatud tehingus tee ROLLBACK ja kõrvalda põhjus.
-- Täpne järjekord ja tulemuste tõlgendus: juurkausta README.md.

BEGIN;

-- 1. Algallikast tuletatud sihtrühm, mitte ainult veel vigaste ridade loendus.
CREATE TEMP TABLE tmp_vetsy_nihke_sihtread ON COMMIT DROP AS
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
FROM vet_analytics.vet_raw AS r WHERE r._id = '691ce762f28d412bf11f0c22';

SELECT toitaine, count(*) AS algallika_sihtread
FROM tmp_vetsy_nihke_sihtread GROUP BY toitaine ORDER BY toitaine;

-- Teistsuguse lähteandmestiku korral ei rakendata vaikimisi ajaloolist parandust.
DO $kontroll$
BEGIN
    IF (SELECT count(*) FROM tmp_vetsy_nihke_sihtread WHERE toitaine = 'mangaan') <> 378
       OR (SELECT count(*) FROM tmp_vetsy_nihke_sihtread WHERE toitaine = 'raud') <> 1
       OR (SELECT count(*) FROM tmp_vetsy_nihke_sihtread WHERE toitaine = 'jood') <> 1
       OR EXISTS (SELECT 1 FROM tmp_vetsy_nihke_sihtread
                  WHERE oodatav_vaartus !~ '^[0-9]+([.][0-9]+)?$') THEN
        RAISE EXCEPTION 'Nihkeparanduse sihtrühm ei vasta selle paketi algsele CSV-le';
    END IF;
END;
$kontroll$;

-- 2. Kõigepealt kolm mangaani numbriteksti kirjaviga (0..3, 1..5, 1..9).
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
    r."minerals.manganese.unit" AS algne_tekst,
    c."minerals.manganese.unit" AS tekst_parast;

-- 3. Seejärel parandame iga toitaine eraldi SQL-lauses.
-- Sama toode võib sisaldada mitut toitaineparandust; järjestikused UPDATE-d
-- väldivad sama rea mitmekordset uuendamist ühe WITH-lause sees.
-- mangaan: algsed sihttingimused ja RETURNING säilivad.
UPDATE vet_analytics.vet_clean AS c
    SET "minerals.manganese.value" = c."minerals.manganese.unit",
        "minerals.manganese.unit" = c."minerals..manganese.unit.1"
    FROM vet_analytics.vet_raw AS r
    WHERE c._id = r._id
      AND c."minerals.manganese.value" = '0'
      AND c."minerals..manganese.unit.1" = 'mg'
      AND c."minerals.manganese.unit" ~ '^[0-9]+([.][0-9]+)?$'
    RETURNING
        'mangaan'::text AS toitaine, c._id, c.product_name_fi,
        r."minerals.manganese.value" AS algne_vaartus,
        r."minerals.manganese.unit" AS algne_uhik,
        c."minerals.manganese.value" AS uus_vaartus,
        c."minerals.manganese.unit" AS uus_uhik;

-- raud: algsed sihttingimused ja RETURNING säilivad.
UPDATE vet_analytics.vet_clean AS c
    SET "trace_elements.iron.value" = c."trace_elements.iron.unit",
        "trace_elements.iron.unit" = 'mg'
    FROM vet_analytics.vet_raw AS r
    WHERE c._id = r._id
      AND c._id = '691ce762f28d412bf11f0c46'
      AND c."trace_elements.iron.value" = '0'
      AND c."trace_elements.iron.unit" = '20'
    RETURNING
        'raud'::text AS toitaine, c._id, c.product_name_fi,
        r."trace_elements.iron.value" AS algne_vaartus,
        r."trace_elements.iron.unit" AS algne_uhik,
        c."trace_elements.iron.value" AS uus_vaartus,
        c."trace_elements.iron.unit" AS uus_uhik;

-- jood: algsed sihttingimused ja RETURNING säilivad.
UPDATE vet_analytics.vet_clean AS c
    SET "minerals.iodine.value" = c."minerals.iodine.unit",
        "minerals.iodine.unit" = 'mg'
    FROM vet_analytics.vet_raw AS r
    WHERE c._id = r._id
      AND c._id = '691ce762f28d412bf11f0c22'
      AND c."minerals.iodine.value" = '0'
      AND c."minerals.iodine.unit" = '0.71'
    RETURNING
        'jood'::text AS toitaine, c._id, c.product_name_fi,
        r."minerals.iodine.value" AS algne_vaartus,
        r."minerals.iodine.unit" AS algne_uhik,
        c."minerals.iodine.value" AS uus_vaartus,
        c."minerals.iodine.unit" AS uus_uhik;

-- 4. Kõigi algallika sihtridade järelkontroll, ka korduskäivitamisel.
WITH sihtread AS (SELECT * FROM tmp_vetsy_nihke_sihtread),
praegune AS (
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
       count(*) FILTER (WHERE leitud_id IS NULL OR praegune_uhik IS DISTINCT FROM 'mg' OR praegune_vaartus IS DISTINCT FROM oodatav_vaartus) AS veel_vigaseid_ridu
FROM praegune GROUP BY toitaine ORDER BY toitaine;

DO $kontroll$
BEGIN
    IF EXISTS (
        WITH sihtread AS (SELECT * FROM tmp_vetsy_nihke_sihtread),
        praegune AS (
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
        SELECT 1 FROM praegune WHERE leitud_id IS NULL OR praegune_uhik IS DISTINCT FROM 'mg' OR praegune_vaartus IS DISTINCT FROM oodatav_vaartus
    ) THEN
        RAISE EXCEPTION 'Nihkeparanduse järelkontroll ebaõnnestus; muudatused ei kinnitata';
    END IF;
END;
$kontroll$;

COMMIT;
