-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 90_VALIKULISED_KONTROLLID | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Fail: 002.03_audititabeli_tootenimed.sql
-- Etapp: VALIKULINE | Uuendatud: 05.10.2026
-- Eesmärk: Täidab olemasoleva ühikuauditi puuduvaid tootenimesid.
-- Eeldus: unit_anomalies audititabel on eraldi loodud ja sisaldab row_id ning product_name veerge.
-- Tulemus: Auditi nimi võetakse FI väljast või selle puudumisel EN väljast.
-- Muudab: Muudab üksnes unit_anomalies.product_name; vet_clean tootenimesid ei muuda.
-- Kasutamine: ava sama sihtbaasi ühenduses ja käivita kogu fail (Alt+X).
-- Vea korral peatu; avatud tehingus tee ROLLBACK ja kõrvalda põhjus.
-- Täpne järjekord ja tulemuste tõlgendus: juurkausta README.md.

-- See fail ei kuulu kuue faili põhitaastamisjärjekorda.
BEGIN;

DO $kontroll$
BEGIN
    IF to_regclass('vet_analytics.unit_anomalies') IS NULL THEN
        RAISE EXCEPTION 'Valikuline audititabel unit_anomalies puudub. Põhitaastamisel jäta see fail vahele.';
    END IF;
END;
$kontroll$;

-- UPDATE muudab unit_anomalies tootenimesid. Vajab unit_anomalies ja vet_clean ning sobivaid _id/row_id tüüpe. Ei muuda vet_clean.
-- Number on lugemisjärjekord, MITTE käsk kõiki faile järjest käivitada.

-- STEP 02.2A
-- Täidame unit_anomalies tabelis puuduva product_name väärtuse.
--
-- Eelistus:
-- 1. product_name_fi
-- 2. kui soomekeelne nimi puudub, product_name_en
--
-- vet_clean tabelit EI MUUDETA.

UPDATE vet_analytics.unit_anomalies AS ua
SET product_name =
    COALESCE(
        NULLIF(BTRIM(vc.product_name_fi), ''),
        NULLIF(BTRIM(vc.product_name_en), '')
    )
FROM vet_analytics.vet_clean AS vc
WHERE ua.row_id = vc._id
  AND NULLIF(BTRIM(ua.product_name), '') IS NULL;

COMMIT;
