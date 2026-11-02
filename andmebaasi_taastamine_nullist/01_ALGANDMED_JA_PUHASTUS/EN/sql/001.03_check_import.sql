-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 01_ALGANDMED_JA_PUHASTUS | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- File: 001.03_check_import.sql
-- Stage: 02 | Updated: 05.10.2026
-- Purpose: validates the completed CSV import.
-- Prerequisite: the original CSV has been imported into vet_analytics.vet_raw.
-- Expected result: 15,202 rows, 15,202 distinct IDs, 0 missing IDs and 215 TEXT columns.
-- Changes: no table or data changes; an invalid import raises an error.
-- Usage: open the file using the same target database connection and run the entire script (Alt+X).
-- If an error occurs, stop; use ROLLBACK if a transaction is open, and fix the cause.
-- For the exact sequence and interpretation of results, see README.md in the package root.

-- All indicators are returned together. Reimporting increases the row count and causes validation to fail.
SELECT count(*) AS row_count,
       count(DISTINCT _id) AS distinct_ids,
       count(*) FILTER (WHERE NULLIF(btrim(_id), '') IS NULL) AS missing_ids,
       count(*) - count(DISTINCT _id)
         - count(*) FILTER (WHERE _id IS NULL) AS duplicate_id_records
FROM vet_analytics.vet_raw;

SELECT count(*) AS column_count,
       count(*) FILTER (WHERE data_type <> 'text') AS non_text_columns
FROM information_schema.columns
WHERE table_schema = 'vet_analytics' AND table_name = 'vet_raw';

-- Do not continue to the next script if import validation fails.
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
