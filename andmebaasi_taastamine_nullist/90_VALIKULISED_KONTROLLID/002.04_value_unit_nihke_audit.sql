-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 90_VALIKULISED_KONTROLLID | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- 002.04 | ABITABEL
-- Salvestab numbrilised ühikud kontrolltabelisse. Leid ei kinnita iseenesest nihke põhjust.
-- Allikas: 12_Veerus ühiku asemel number.sql
-- Käivita selles paketis ainult ühe korra ja selles järjekorras.

-- ÜLEVAATUS 24.09.2026. Algfail: Veerus ühiku asemel number.sql
-- DROP + CREATE + INSERT asendab value_unit_shift_anomalies tabeli. Topeltpunktide ühtlustamine ja lõppude eemaldamine võib anda ühele value-veergule mitu unit-vastet. Number ühikuveerus on kontrollisignaal, mitte kinnitatud nihke põhjus.
-- Number on lugemisjärjekord, MITTE käsk kõiki faile järjest käivitada.

-- ============================================================
-- STEP 03.4 – NUMBRILINE VÄÄRTUS UNIT-VEERUS
--
-- Eesmärk:
-- leida value/unit paarid, kus .unit veerus on number.
--
-- Näited:
-- unit = 20
-- unit = 0.71
-- unit = 0.3
--
-- vet_clean andmeid EI MUUDETA.
-- ============================================================

-- Kustutavat DROP käsku ei kasutata; alusta uuest tühjast andmebaasist.

CREATE TABLE vet_analytics.value_unit_shift_anomalies (
    row_id TEXT,
    product_name TEXT,
    value_column TEXT,
    unit_column TEXT,
    value_original TEXT,
    unit_original TEXT,
    flag TEXT
);

DO $$
DECLARE
    c RECORD;
BEGIN

    FOR c IN
        SELECT
            v.column_name AS value_column,
            u.column_name AS unit_column
        FROM information_schema.columns v

        JOIN information_schema.columns u
          ON regexp_replace(
                 replace(v.column_name, '..', '.'),
                 '\.value.*$',
                 ''
             )
           =
             regexp_replace(
                 replace(u.column_name, '..', '.'),
                 '\.unit.*$',
                 ''
             )

        WHERE v.table_schema = 'vet_analytics'
          AND v.table_name = 'vet_clean'
          AND v.column_name LIKE '%.value%'

          AND u.table_schema = 'vet_analytics'
          AND u.table_name = 'vet_clean'
          AND u.column_name LIKE '%.unit%'

    LOOP

        EXECUTE format(
            'INSERT INTO vet_analytics.value_unit_shift_anomalies
             (
                 row_id,
                 product_name,
                 value_column,
                 unit_column,
                 value_original,
                 unit_original,
                 flag
             )

             SELECT
                 _id,
                 COALESCE(
                     NULLIF(BTRIM(product_name_fi), ''''),
                     NULLIF(BTRIM(product_name_en), '''')
                 ),
                 %L,
                 %L,
                 %I::text,
                 %I::text,
                 ''NUMERIC_IN_UNIT''

             FROM vet_analytics.vet_clean

             WHERE BTRIM(%I::text)
                   ~ ''^[+-]?[0-9]+([.,][0-9]+)?$''',

            c.value_column,
            c.unit_column,
            c.value_column,
            c.unit_column,
            c.unit_column
        );

    END LOOP;

END $$;


-- vaata tulemust

SELECT *
FROM vet_analytics.value_unit_shift_anomalies
ORDER BY unit_column, row_id;

-- viitab tugevalt sellele, et numbriline toitaineväärtus on sattunud valesse veergu
