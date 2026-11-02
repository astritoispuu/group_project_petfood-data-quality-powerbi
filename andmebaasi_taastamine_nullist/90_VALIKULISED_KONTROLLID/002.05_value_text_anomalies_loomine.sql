-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 90_VALIKULISED_KONTROLLID | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- 002.05 | ABITABEL
-- Salvestab ebatavalise tekstiga .value väljad, sh algsed topeltpunktid.
-- Allikas: 13_mittenumbriline sisu .value veergudes.sql
-- Käivita selles paketis ainult ühe korra ja selles järjekorras.

-- ÜLEVAATUS 24.09.2026. Algfail: mittenumbriline sisu .value veergudes
-- DROP + CREATE + INSERT asendab value_text_anomalies audititabeli. Lihtne numbrimustri kontroll märgib ka nt teadusliku kirjaviisi ülevaatuseks. Ei muuda vet_clean.
-- Number on lugemisjärjekord, MITTE käsk kõiki faile järjest käivitada.

-- ============================================================
-- STEP 03.5A – MITTENUMBRILINE / VIGASE FORMAADIGA SISU
--              .value VEERGUDES
--
-- Eesmärk:
-- leida kõik .value veergude väärtused, mis ei ole
-- korrektses numbriformaadis.
--
-- Näiteks leitakse:
-- mg
-- IE
-- %
-- N/A
-- 0..3
-- 3601..82
-- muu tekst
--
-- Tulemus salvestatakse püsivasse audititabelisse:
-- vet_analytics.value_text_anomalies
--
-- vet_clean ANDMEID EI MUUDETA.
-- ============================================================


-- Kustutame ainult varasema audititabeli,
-- et kontroll saaks iga kord värskelt uuesti tekkida.
-- Kustutavat DROP käsku ei kasutata; alusta uuest tühjast andmebaasist.


-- Loome püsiva audititabeli.
CREATE TABLE vet_analytics.value_text_anomalies (
    row_id TEXT,
    product_name TEXT,
    value_column TEXT,
    value_original TEXT
);


-- Käime automaatselt läbi kõik .value veerud.
DO $$
DECLARE
    c TEXT;
BEGIN

    FOR c IN
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'vet_analytics'
          AND table_name = 'vet_clean'
          AND column_name LIKE '%.value%'
        ORDER BY ordinal_position

    LOOP

        EXECUTE format(
            'INSERT INTO vet_analytics.value_text_anomalies
             (
                 row_id,
                 product_name,
                 value_column,
                 value_original
             )

             SELECT
                 _id,

                 COALESCE(
                     NULLIF(BTRIM(product_name_fi), ''''),
                     NULLIF(BTRIM(product_name_en), '''')
                 ),

                 %L,

                 %I::text

             FROM vet_analytics.vet_clean

             WHERE NULLIF(BTRIM(%I::text), '''') IS NOT NULL

               AND BTRIM(%I::text)
                   !~ ''^[+-]?([0-9]+([.,][0-9]*)?|[.,][0-9]+)$''',

            c,
            c,
            c,
            c
        );

    END LOOP;

END $$;


-- Kuvame leitud anomaaliad.
SELECT
    row_id,
    product_name,
    value_column,
    value_original
FROM vet_analytics.value_text_anomalies
ORDER BY value_column, product_name;
