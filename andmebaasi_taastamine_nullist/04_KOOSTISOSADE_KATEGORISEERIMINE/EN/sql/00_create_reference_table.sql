-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 04_KOOSTISOSADE_KATEGORISEERIMINE | VERSIOON: 2026-10-05
-- AUTORLUS: Liina töövoog; taastamise kontroll-/struktuurifail.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- SCRIPT: 00_create_reference_table.sql
-- STEP ID: CAT_STEP_00
-- PURPOSE: Create CSV reference table
-- INPUT: categories_reference.csv
-- OUTPUT: vet_analytics.ingredients_categories_reference
-- PREREQUISITES: README.md
-- VALIDATION: 03_validation.sql
-- EXECUTION LOG: EXECUTION_LOG.md
-- EXECUTION STATUS: NOT_RUN
-- ORIGINAL WORK: Supplementary validation/restoration script for Liina's workflow, added 2026-10-05
-- REVISION: 2026-10-05
-- SOURCE POLICY: Source tables are preserved
-- RUN POLICY: README.md

-- Create the schema and all seven CSV headers; existing data is not cleared.
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
-- If an older reference has five columns, add the two CSV audit fields.
ALTER TABLE vet_analytics.ingredients_categories_reference
    ADD COLUMN IF NOT EXISTS "Human Review" TEXT,
    ADD COLUMN IF NOT EXISTS "Review Reason" TEXT;
