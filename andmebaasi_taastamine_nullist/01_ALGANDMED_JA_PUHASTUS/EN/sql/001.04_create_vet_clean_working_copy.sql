-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 01_ALGANDMED_JA_PUHASTUS | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- File: 001.04_create_vet_clean_working_copy.sql
-- Stage: 03 | Updated: 05.10.2026
-- Purpose: creates an exact working copy of the original data and a unique ID index.
-- Prerequisite: 001.03 has passed; vet_clean does not yet exist.
-- Expected result: vet_clean initially contains the same 15,202 rows and 215 columns as vet_raw.
-- Changes: creates vet_clean and the vet_clean_id_uq index; does not change vet_raw data.
-- Usage: open the file using the same target database connection and run the entire script (Alt+X).
-- If an error occurs, stop; use ROLLBACK if a transaction is open, and fix the cause.
-- For the exact sequence and interpretation of results, see README.md in the package root.

BEGIN;

-- Repeat the import check here so working-copy creation does not depend solely on a manual decision.
DO $validation$
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
        RAISE EXCEPTION 'Import does not match the original source: rows %, distinct IDs %, missing IDs %, columns %, non-TEXT %',
            n, ids, blank_ids, cols, not_text;
    END IF;
END;
$validation$;

CREATE TABLE vet_analytics.vet_clean AS
SELECT * FROM vet_analytics.vet_raw;

CREATE UNIQUE INDEX vet_clean_id_uq ON vet_analytics.vet_clean (_id);

-- The initial copy must contain exactly the same values as the source table.
DO $validation$
BEGIN
    IF EXISTS (
        (SELECT * FROM vet_analytics.vet_raw
         EXCEPT ALL SELECT * FROM vet_analytics.vet_clean)
        UNION ALL
        (SELECT * FROM vet_analytics.vet_clean
         EXCEPT ALL SELECT * FROM vet_analytics.vet_raw)
    ) THEN
        RAISE EXCEPTION 'vet_clean is not an exact copy of the source table';
    END IF;
END;
$validation$;

SELECT 'vet_raw' AS table_name, count(*) AS row_count FROM vet_analytics.vet_raw
UNION ALL
SELECT 'vet_clean', count(*) FROM vet_analytics.vet_clean;

COMMIT;
