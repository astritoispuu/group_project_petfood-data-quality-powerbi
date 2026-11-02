-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 04_KOOSTISOSADE_KATEGORISEERIMINE | VERSIOON: 2026-10-05
-- AUTORLUS: Liina töövoog; taastamise kontroll-/struktuurifail.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- SCRIPT: fact_ingredients_loomine.sql
-- STEP ID: CAT_STEP_01
-- PURPOSE: Create the existing BI fact structure
-- INPUT: README.md
-- OUTPUT: vet_powerbi.fact_ingredients
-- PREREQUISITES: README.md
-- VALIDATION: 03_validation.sql
-- EXECUTION LOG: EXECUTION_LOG.md
-- EXECUTION STATUS: NOT_RUN
-- ORIGINAL WORK: Original code by Liina; compatibility revision 2026-10-05
-- REVISION: 2026-10-05
-- SOURCE POLICY: Source tables are preserved
-- RUN POLICY: README.md

-- Create only the structure; preserve an existing table and its data.
CREATE SCHEMA IF NOT EXISTS vet_powerbi;
CREATE TABLE IF NOT EXISTS vet_powerbi.fact_ingredients (
    "product_id" TEXT,
    "ingredient" TEXT,
    "category" TEXT,
    "protein" TEXT,
    "oil" TEXT,
    "carbs" TEXT
);
-- Check that an existing fact contains all six required columns.
DO $$
DECLARE
    missing_columns TEXT;
BEGIN
    SELECT string_agg(required.name, ', ' ORDER BY required.name)
    INTO missing_columns
    FROM (VALUES ('product_id'), ('ingredient'), ('category'),
                 ('protein'), ('oil'), ('carbs')) AS required(name)
    WHERE NOT EXISTS (
        SELECT 1 FROM information_schema.columns AS actual
        WHERE actual.table_schema = 'vet_powerbi'
          AND actual.table_name = 'fact_ingredients'
          AND actual.column_name = required.name
    );
    IF missing_columns IS NOT NULL THEN
        RAISE EXCEPTION 'vet_powerbi.fact_ingredients: missing columns: %', missing_columns;
    END IF;
END $$;
