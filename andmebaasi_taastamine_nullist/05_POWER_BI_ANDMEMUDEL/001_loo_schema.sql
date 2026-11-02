-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 05_POWER_BI_ANDMEMUDEL | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Loob skeemi; taastatud olemasolev skeem säilib.
-- DROP SCHEMA vet_powerbi CASCADE ei kuulu taastamise käivitusjärjekorda.
-- fact_ingredients on nüüd selles skeemis ainus kategoriseerimise väljundtabel.
CREATE SCHEMA IF NOT EXISTS vet_powerbi;
