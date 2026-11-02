-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 90_VALIKULISED_KONTROLLID | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- 002.01 | ABIKOOD
-- Näitab kasutatud ühikuid ja nende sagedusi.
-- Allikas: 06_Veerus unit kasutatud ühikud.sql
-- Käivita selles paketis ainult ühe korra ja selles järjekorras.

-- ÜLEVAATUS 24.09.2026. Algfail: Veerus unit kasutatud ühikud.sql
-- Ajutise audititabeli loomine ja täitmine. Algne DROP TABLE on skeemita: samanimelise püsitabeli eemaldamise võimalus. Korrastatud koopias piiratud pg_temp skeemiga.
-- Number on lugemisjärjekord, MITTE käsk kõiki faile järjest käivitada.

-- ============================================================
-- STEP 02.1 – KASUTATUD ÜHIKUTE AUDIT
--
-- Eesmärk:
-- 1. leida kõik vet_clean tabeli veerud, mille nimes on ".unit"
-- 2. koguda nende veergude kõik mittetühjad väärtused
-- 3. lugeda, mitu korda iga ühiku kuju esineb
--
-- vet_clean andmeid EI MUUDETA.
-- Luuakse ainult ajutine tabel kontrolli tegemiseks.
-- ============================================================


-- Kui eelmisest katsest on ajutine tabel olemas,
-- kustutame ainult selle ajutise tabeli.
DROP TABLE IF EXISTS pg_temp.temp_unit_values;


-- Loome AJUTISE tabeli,
-- kuhu kogume kõik unit-veergudest leitud väärtused.
CREATE TEMP TABLE temp_unit_values (
    column_name TEXT,
    unit_value  TEXT
);


-- Käime automaatselt läbi kõik veerud,
-- mille nimes sisaldub ".unit".
DO $$
DECLARE
    c RECORD;
BEGIN

    FOR c IN
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'vet_analytics'
          AND table_name = 'vet_clean'
          AND column_name LIKE '%.unit%'
        ORDER BY ordinal_position

    LOOP

        EXECUTE format(
            'INSERT INTO temp_unit_values (column_name, unit_value)
             SELECT %L, %I::text
             FROM vet_analytics.vet_clean
             WHERE NULLIF(BTRIM(%I::text), '''') IS NOT NULL',
            c.column_name,
            c.column_name,
            c.column_name
        );

    END LOOP;

END $$;


-- Kuvame kõik leitud ühikute erinevad kujud
-- ja loeme, mitu korda igaüks esineb.

SELECT
    unit_value AS unit_original,
    COUNT(*) AS occurrence_count,
    COUNT(DISTINCT column_name) AS unit_columns_count
FROM temp_unit_values
GROUP BY unit_value
ORDER BY occurrence_count DESC, unit_original;
