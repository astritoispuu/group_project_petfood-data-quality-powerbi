-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 01_ALGANDMED_JA_PUHASTUS | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Fail: 001.03_impordi_kontroll.sql
-- Etapp: 02 | Uuendatud: 05.10.2026
-- Eesmärk: Kontrollib lõpetatud CSV importi.
-- Eeldus: Algne CSV on imporditud vet_analytics.vet_raw tabelisse.
-- Tulemus: 15 202 rida, 15 202 eri ID-d, 0 tühja ID-d ja 215 TEXT veergu.
-- Muudab: Ei muuda tabeleid ega andmeid; sobimatu import põhjustab vea.
-- Kasutamine: ava sama sihtbaasi ühenduses ja käivita kogu fail (Alt+X).
-- Vea korral peatu; avatud tehingus tee ROLLBACK ja kõrvalda põhjus.
-- Täpne järjekord ja tulemuste tõlgendus: juurkausta README.md.

-- Kõik näitajad on ühes tulemuses. Kordusimport suurendab ridu ja põhjustab vea.
SELECT count(*) AS ridu,
       count(DISTINCT _id) AS unikaalseid_id,
       count(*) FILTER (WHERE NULLIF(btrim(_id), '') IS NULL) AS puuduvaid_id,
       count(*) - count(DISTINCT _id)
         - count(*) FILTER (WHERE _id IS NULL) AS korduvaid_id_kirjeid
FROM vet_analytics.vet_raw;

SELECT count(*) AS veerge,
       count(*) FILTER (WHERE data_type <> 'text') AS mitte_text_veerge
FROM information_schema.columns
WHERE table_schema = 'vet_analytics' AND table_name = 'vet_raw';

-- Vigase impordi korral ei tohi järgmise failiga jätkata.
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
