-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 04_KOOSTISOSADE_KATEGORISEERIMINE | VERSIOON: 2026-10-05
-- AUTORLUS: Liina töövoog; taastamise kontroll-/struktuurifail.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- SCRIPT: 00_create_reference_table.sql
-- STEP ID: CAT_STEP_00
-- PURPOSE: Loo CSV võrdlustabel
-- INPUT: categories_reference.csv
-- OUTPUT: vet_analytics.ingredients_categories_reference
-- PREREQUISITES: README.md
-- VALIDATION: 03_validation.sql
-- EXECUTION LOG: EXECUTION_LOG.md
-- EXECUTION STATUS: NOT_RUN
-- ORIGINAL WORK: Liina töövoogu täiendav kontroll-/taastamisskript, lisatud 05.10.2026
-- REVISION: 2026-10-05
-- SOURCE POLICY: Sisendtabelid säilivad
-- RUN POLICY: README.md

-- Loo skeem ja kõik seitse CSV päist; olemasolevaid andmeid ei tühjendata.
CREATE SCHEMA IF NOT EXISTS vet_analytics;
CREATE TABLE IF NOT EXISTS vet_analytics.ingredients_categories_reference (
    "Ingredient" TEXT,
    "Category" TEXT,
    "Human Review" TEXT,
    "Review Reason" TEXT,
    "Protein" TEXT,
    "Oil" TEXT,
    "Carbs" TEXT
);
-- Kui võrdlustabel loodi varem ainult viie veeruga, lisa kaks CSV auditivälja.
ALTER TABLE vet_analytics.ingredients_categories_reference
    ADD COLUMN IF NOT EXISTS "Human Review" TEXT,
    ADD COLUMN IF NOT EXISTS "Review Reason" TEXT;
