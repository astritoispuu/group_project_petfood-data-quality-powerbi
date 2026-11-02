-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 90_VALIKULISED_KONTROLLID | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- 002.02 | ABITABEL
-- Loob kontrolltabeli ülevaatust vajavate ühikutega; märge CHECK_UNIT ei tähenda automaatselt viga.
-- Allikas: 07_Tabeli loomine anomaalsete ühikutega veerud.sql
-- Käivita selles paketis ainult ühe korra ja selles järjekorras.

-- ÜLEVAATUS 24.09.2026. Algfail: Tabeli loomine anomaalsete ühikutega veerud.sql
-- DROP + CREATE + INSERT asendab unit_anomalies audititabeli. Säilitatud varasemad auditimärkmed võivad kaduda. CHECK_UNIT tähendab ülevaatuse vajadust, mitte tõestatud viga; lubatud loend ei sisalda nt % ega kõiki mikrogrammi kirjapilte.
-- Number on lugemisjärjekord, MITTE käsk kõiki faile järjest käivitada.

-- ============================================================
-- STEP 02.2 – ANOMAALSETE ÜHIKUTE FLAGIMINE
--
-- Eesmärk:
-- leida kõik .unit veergude väärtused, mis EI OLE:
-- mg, IE, kcal, kJ, g või µg
--
-- Algseid andmeid vet_clean tabelis EI MUUDETA.
-- Tulemused salvestatakse eraldi kontrolltabelisse.
-- ============================================================

-- MIS PEAKS OLEMA ÜHIKUKS LAHTRITES dry_matter.unit, proteins.crude_protein.unit, crude_fat.unit, crude_fibre.unit, ash.unit, moisture.unit?


-- Kui varasem kontrolltabel on olemas, kustutame selle
-- ja loome värske tulemuse.
-- Kustutavat DROP käsku ei kasutata; alusta uuest tühjast andmebaasist.


-- Loome tabeli, kuhu salvestame leitud probleemid.
CREATE TABLE vet_analytics.unit_anomalies (
    row_id TEXT,
    product_name TEXT,
    column_name TEXT,
    unit_original TEXT,
    flag TEXT
);


-- Käime läbi kõik .unit veerud.
DO $$
DECLARE
    c TEXT;
BEGIN

    FOR c IN
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'vet_analytics'
          AND table_name = 'vet_clean'
          AND column_name LIKE '%.unit%'
    LOOP

        EXECUTE format(
            'INSERT INTO vet_analytics.unit_anomalies
                (row_id, product_name, column_name, unit_original, flag)

             SELECT
                _id,
                product_name_fi,
                %L,
                %I::text,
                ''CHECK_UNIT''

             FROM vet_analytics.vet_clean

             WHERE NULLIF(BTRIM(%I::text), '''') IS NOT NULL
               AND %I::text NOT IN
                   (''mg'', ''IE'', ''kcal'', ''kJ'', ''g'', ''µg'')',

            c,
            c,
            c,
            c
        );

    END LOOP;

END $$;
