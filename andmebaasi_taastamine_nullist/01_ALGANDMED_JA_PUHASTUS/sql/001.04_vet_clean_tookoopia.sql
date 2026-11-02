-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 01_ALGANDMED_JA_PUHASTUS | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Fail: 001.04_vet_clean_tookoopia.sql
-- Etapp: 03 | Uuendatud: 05.10.2026
-- Eesmärk: Loob algandmete täpse töökoopia ja unikaalse ID indeksi.
-- Eeldus: 001.03 on läbitud; vet_clean tabelit veel ei ole.
-- Tulemus: vet_clean sisaldab alguses samu 15 202 rida ja 215 veergu kui vet_raw.
-- Muudab: Loob vet_clean tabeli ja vet_clean_id_uq indeksi; vet_raw andmeid ei muuda.
-- Kasutamine: ava sama sihtbaasi ühenduses ja käivita kogu fail (Alt+X).
-- Vea korral peatu; avatud tehingus tee ROLLBACK ja kõrvalda põhjus.
-- Täpne järjekord ja tulemuste tõlgendus: juurkausta README.md.

BEGIN;

-- Kontroll korratakse ka siin, et töökoopia loomine ei sõltuks käsitsi otsusest.
DO $kontroll$
DECLARE
    n bigint;
    ids bigint;
    blank_ids bigint;
    cols integer;
    not_text integer;
BEGIN
    SELECT count(*), count(DISTINCT _id),
           count(*) FILTER (WHERE NULLIF(btrim(_id), '') IS NULL)
    INTO n, ids, blank_ids
    FROM vet_analytics.vet_raw;
    SELECT count(*), count(*) FILTER (WHERE data_type <> 'text')
    INTO cols, not_text
    FROM information_schema.columns
    WHERE table_schema = 'vet_analytics' AND table_name = 'vet_raw';
    IF n <> 15202 OR ids <> n OR blank_ids <> 0 OR cols <> 215 OR not_text <> 0 THEN
        RAISE EXCEPTION 'Import ei vasta algallikale: read %, eri ID-d %, tühjad ID-d %, veerud %, mitte-TEXT %',
            n, ids, blank_ids, cols, not_text;
    END IF;
END;
$kontroll$;

CREATE TABLE vet_analytics.vet_clean AS
SELECT * FROM vet_analytics.vet_raw;

CREATE UNIQUE INDEX vet_clean_id_uq ON vet_analytics.vet_clean (_id);

-- Esialgne koopia peab olema väärtuste poolest identne algtabeliga.
DO $kontroll$
BEGIN
    IF EXISTS (
        (SELECT * FROM vet_analytics.vet_raw
         EXCEPT ALL SELECT * FROM vet_analytics.vet_clean)
        UNION ALL
        (SELECT * FROM vet_analytics.vet_clean
         EXCEPT ALL SELECT * FROM vet_analytics.vet_raw)
    ) THEN
        RAISE EXCEPTION 'vet_clean ei ole algtabeli täpne koopia';
    END IF;
END;
$kontroll$;

SELECT 'vet_raw' AS tabel, count(*) AS ridu FROM vet_analytics.vet_raw
UNION ALL
SELECT 'vet_clean', count(*) FROM vet_analytics.vet_clean;

COMMIT;
