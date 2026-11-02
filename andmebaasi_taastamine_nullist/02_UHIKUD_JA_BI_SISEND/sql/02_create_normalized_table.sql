-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 02_UHIKUD_JA_BI_SISEND | VERSIOON: 2026-10-05
-- AUTORLUS: Oksana – algne normaliseerimisloogika ja vastendused.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Original normalization logic and nutrient mappings: Oksana.
-- Compatibility review and documentation: 2026-10-05.
-- Rebuild the intermediate table from vet_clean using Oksana's 49 mappings.
-- Execute the whole script. If it fails, execute ROLLBACK before retrying.
BEGIN;

DO $check_and_create$
DECLARE
    v_count integer;
    v_b1_value text;
    v_b1_unit text;
    v_missing text;
    v_collisions text;
BEGIN
    IF to_regclass('vet_analytics.vet_clean') IS NULL THEN
        RAISE EXCEPTION 'Source table vet_analytics.vet_clean does not exist.';
    END IF;
    -- Match the actual B1 headers without renaming source columns.
    SELECT count(*), min(column_name)
    INTO v_count, v_b1_value
    FROM information_schema.columns
    WHERE table_schema = 'vet_analytics' AND table_name = 'vet_clean'
      AND column_name IN ('vitamins..b1_vitamin.value', 'vitamins.b1_vitamin.value');
    IF v_count <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one B1 value column; found %. Inspect vet_clean headers.', v_count;
    END IF;

    SELECT count(*), min(column_name)
    INTO v_count, v_b1_unit
    FROM information_schema.columns
    WHERE table_schema = 'vet_analytics' AND table_name = 'vet_clean'
      AND column_name IN ('vitamins..b1_vitamin.unit', 'vitamins.b1_vitamin.unit');
    IF v_count <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one B1 unit column; found %. Inspect vet_clean headers.', v_count;
    END IF;

    -- Validate all fixed headers before removing the previous output.
    SELECT string_agg(r.column_name, ', ' ORDER BY r.column_name)
    INTO v_missing
    FROM unnest(ARRAY[
        'proteins.crude_protein.value',
        'proteins.crude_protein.unit',
        'proteins.digestible_protein_from_AA.value',
        'proteins.digestible_protein_from_AA.unit',
        'crude_fat.value',
        'crude_fat.unit',
        'crude_fibre.value',
        'crude_fibre.unit',
        'ash.value',
        'ash.unit',
        'vitamins.a_vitamin.value',
        'vitamins.a_vitamin.unit',
        'vitamins.b2_vitamin.value',
        'vitamins.b2_vitamin.unit',
        'vitamins.b6_vitamin.value',
        'vitamins.b6_vitamin.unit',
        'vitamins.b12_vitamin.value',
        'vitamins.b12_vitamin.unit',
        'vitamins.d3_vitamin.value',
        'vitamins.d3_vitamin.unit',
        'vitamins.e_vitamin.value',
        'vitamins.e_vitamin.unit',
        'vitamins.pantothenic_acid.value',
        'vitamins.pantothenic_acid.unit',
        'vitamins.niacin.value',
        'vitamins.niacin.unit',
        'vitamins.folic_acid.value',
        'vitamins.folic_acid.unit',
        'vitamins.biotin.value',
        'vitamins.biotin.unit',
        'vitamins.c_vitamin.value',
        'vitamins.c_vitamin.unit',
        'vitamins.k_vitamin.value',
        'vitamins.k_vitamin.unit',
        'fatty_acids.linoleic_acid.value',
        'fatty_acids.linoleic_acid.unit',
        'vitamins.linoleic_acid.value',
        'vitamins.linoleic_acid.unit',
        'trace_elements.iron.value',
        'trace_elements.iron.unit',
        'trace_elements.zinc.value',
        'trace_elements.zinc.unit',
        'trace_elements.copper.value',
        'trace_elements.copper.unit',
        'trace_elements.copper_sulfate.value',
        'trace_elements.copper_sulfate.unit',
        'minerals.calsium.value',
        'minerals.calsium.unit',
        'minerals.phosphorous.value',
        'minerals.phosphorous.unit',
        'minerals.magnesium.value',
        'minerals.magnesium.unit',
        'minerals.sodium.value',
        'minerals.sodium.unit',
        'minerals.potassium.value',
        'minerals.potassium.unit',
        'minerals.iodine.value',
        'minerals.iodine.unit',
        'minerals.manganese.value',
        'minerals.manganese.unit',
        'minerals.selenium.value',
        'minerals.selenium.unit',
        'minerals.cobalt.value',
        'minerals.cobalt.unit',
        'minerals.natrium.value',
        'minerals.natrium.unit',
        'aminoacids.lysine.value',
        'aminoacids.lysine.unit',
        'aminoacids.methionine.value',
        'aminoacids.methionine.unit',
        'aminoacids.taurine.value',
        'aminoacids.taurine.unit',
        'aminoacids.arginine.value',
        'aminoacids.arginine.unit',
        'aminoacids.isoleucine.value',
        'aminoacids.isoleucine.unit',
        'aminoacids.leucine.value',
        'aminoacids.leucine.unit',
        'aminoacids.cystine.value',
        'aminoacids.cystine.unit',
        'aminoacids.phenylalanine.value',
        'aminoacids.phenylalanine.unit',
        'aminoacids.tyrosine.value',
        'aminoacids.tyrosine.unit',
        'aminoacids.threonine.value',
        'aminoacids.threonine.unit',
        'aminoacids.tryptophan.value',
        'aminoacids.tryptophan.unit',
        'aminoacids.valine.value',
        'aminoacids.valine.unit',
        'aminoacids.histidine.value',
        'aminoacids.histidine.unit',
        'nutrient.choline.value',
        'nutrient.choline.unit',
        'nfe.value',
        'nfe.unit',
        '_id'
    ]::text[]) AS r(column_name)
    WHERE NOT EXISTS (
        SELECT 1 FROM information_schema.columns c
        WHERE c.table_schema = 'vet_analytics' AND c.table_name = 'vet_clean'
          AND c.column_name = r.column_name
    );
    IF v_missing IS NOT NULL THEN
        RAISE EXCEPTION 'Missing vet_clean columns: %', v_missing;
    END IF;

    -- v.* must not already contain one of the new output names.
    SELECT string_agg(column_name, ', ' ORDER BY column_name)
    INTO v_collisions
    FROM information_schema.columns
    WHERE table_schema = 'vet_analytics' AND table_name = 'vet_clean'
      AND column_name = ANY(ARRAY['crude_protein_mg_kg', 'digestible_protein_from_aa_mg_kg', 'crude_fat_mg_kg', 'crude_fibre_mg_kg', 'ash_mg_kg', 'vitamin_a_mg_kg', 'vitamin_b1_mg_kg', 'vitamin_b2_mg_kg', 'vitamin_b6_mg_kg', 'vitamin_b12_mg_kg', 'vitamin_d3_mg_kg', 'vitamin_e_mg_kg', 'pantothenic_acid_mg_kg', 'niacin_mg_kg', 'folic_acid_mg_kg', 'biotin_mg_kg', 'vitamin_c_mg_kg', 'vitamin_k_mg_kg', 'fatty_acids_linoleic_acid_mg_kg', 'vitamins_linoleic_acid_mg_kg', 'iron_mg_kg', 'zinc_mg_kg', 'copper_mg_kg', 'copper_sulfate_mg_kg', 'calsium_mg_kg', 'phosphorous_mg_kg', 'magnesium_mg_kg', 'sodium_mg_kg', 'potassium_mg_kg', 'iodine_mg_kg', 'manganese_mg_kg', 'selenium_mg_kg', 'cobalt_mg_kg', 'natrium_mg_kg', 'lysine_mg_kg', 'methionine_mg_kg', 'taurine_mg_kg', 'arginine_mg_kg', 'isoleucine_mg_kg', 'leucine_mg_kg', 'cystine_mg_kg', 'phenylalanine_mg_kg', 'tyrosine_mg_kg', 'threonine_mg_kg', 'tryptophan_mg_kg', 'valine_mg_kg', 'histidine_mg_kg', 'choline_mg_kg', 'nfe_mg_kg']::text[]);
    IF v_collisions IS NOT NULL THEN
        RAISE EXCEPTION 'vet_clean already contains normalized output names: %', v_collisions;
    END IF;

    RAISE NOTICE 'B1 source columns: % and %', v_b1_value, v_b1_unit;
    -- No CASCADE: dependent database objects must not be deleted implicitly.
    DROP TABLE IF EXISTS vet_analytics.vet_clean_mg_kg;
    EXECUTE format($create_table$
CREATE TABLE vet_analytics.vet_clean_mg_kg AS
SELECT
    v.*,

    -- Proteins
    vet_analytics.convert_to_mg_kg(
        v."proteins.crude_protein.value"::text,
        v."proteins.crude_protein.unit"::text
    ) AS crude_protein_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."proteins.digestible_protein_from_AA.value"::text,
        v."proteins.digestible_protein_from_AA.unit"::text
    ) AS digestible_protein_from_aa_mg_kg,

    -- Basic nutrients
    vet_analytics.convert_to_mg_kg(
        v."crude_fat.value"::text,
        v."crude_fat.unit"::text
    ) AS crude_fat_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."crude_fibre.value"::text,
        v."crude_fibre.unit"::text
    ) AS crude_fibre_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."ash.value"::text,
        v."ash.unit"::text
    ) AS ash_mg_kg,

    -- Vitamins
    vet_analytics.convert_vitamin_to_mg_kg(
        v."vitamins.a_vitamin.value"::text,
        v."vitamins.a_vitamin.unit"::text,
        'a'
    ) AS vitamin_a_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v.%1$I::text,
        v.%2$I::text
    ) AS vitamin_b1_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."vitamins.b2_vitamin.value"::text,
        v."vitamins.b2_vitamin.unit"::text
    ) AS vitamin_b2_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."vitamins.b6_vitamin.value"::text,
        v."vitamins.b6_vitamin.unit"::text
    ) AS vitamin_b6_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."vitamins.b12_vitamin.value"::text,
        v."vitamins.b12_vitamin.unit"::text
    ) AS vitamin_b12_mg_kg,

    vet_analytics.convert_vitamin_to_mg_kg(
        v."vitamins.d3_vitamin.value"::text,
        v."vitamins.d3_vitamin.unit"::text,
        'd3'
    ) AS vitamin_d3_mg_kg,

    vet_analytics.convert_vitamin_to_mg_kg(
        v."vitamins.e_vitamin.value"::text,
        v."vitamins.e_vitamin.unit"::text,
        'e'
    ) AS vitamin_e_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."vitamins.pantothenic_acid.value"::text,
        v."vitamins.pantothenic_acid.unit"::text
    ) AS pantothenic_acid_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."vitamins.niacin.value"::text,
        v."vitamins.niacin.unit"::text
    ) AS niacin_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."vitamins.folic_acid.value"::text,
        v."vitamins.folic_acid.unit"::text
    ) AS folic_acid_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."vitamins.biotin.value"::text,
        v."vitamins.biotin.unit"::text
    ) AS biotin_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."vitamins.c_vitamin.value"::text,
        v."vitamins.c_vitamin.unit"::text
    ) AS vitamin_c_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."vitamins.k_vitamin.value"::text,
        v."vitamins.k_vitamin.unit"::text
    ) AS vitamin_k_mg_kg,

    -- Fatty acids
    vet_analytics.convert_to_mg_kg(
        v."fatty_acids.linoleic_acid.value"::text,
        v."fatty_acids.linoleic_acid.unit"::text
    ) AS fatty_acids_linoleic_acid_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."vitamins.linoleic_acid.value"::text,
        v."vitamins.linoleic_acid.unit"::text
    ) AS vitamins_linoleic_acid_mg_kg,

    -- Trace elements
    vet_analytics.convert_to_mg_kg(
        v."trace_elements.iron.value"::text,
        v."trace_elements.iron.unit"::text
    ) AS iron_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."trace_elements.zinc.value"::text,
        v."trace_elements.zinc.unit"::text
    ) AS zinc_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."trace_elements.copper.value"::text,
        v."trace_elements.copper.unit"::text
    ) AS copper_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."trace_elements.copper_sulfate.value"::text,
        v."trace_elements.copper_sulfate.unit"::text
    ) AS copper_sulfate_mg_kg,

    -- Minerals
    vet_analytics.convert_to_mg_kg(
        v."minerals.calsium.value"::text,
        v."minerals.calsium.unit"::text
    ) AS calsium_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."minerals.phosphorous.value"::text,
        v."minerals.phosphorous.unit"::text
    ) AS phosphorous_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."minerals.magnesium.value"::text,
        v."minerals.magnesium.unit"::text
    ) AS magnesium_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."minerals.sodium.value"::text,
        v."minerals.sodium.unit"::text
    ) AS sodium_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."minerals.potassium.value"::text,
        v."minerals.potassium.unit"::text
    ) AS potassium_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."minerals.iodine.value"::text,
        v."minerals.iodine.unit"::text
    ) AS iodine_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."minerals.manganese.value"::text,
        v."minerals.manganese.unit"::text
    ) AS manganese_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."minerals.selenium.value"::text,
        v."minerals.selenium.unit"::text
    ) AS selenium_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."minerals.cobalt.value"::text,
        v."minerals.cobalt.unit"::text
    ) AS cobalt_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."minerals.natrium.value"::text,
        v."minerals.natrium.unit"::text
    ) AS natrium_mg_kg,

    -- Amino acids
    vet_analytics.convert_to_mg_kg(
        v."aminoacids.lysine.value"::text,
        v."aminoacids.lysine.unit"::text
    ) AS lysine_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."aminoacids.methionine.value"::text,
        v."aminoacids.methionine.unit"::text
    ) AS methionine_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."aminoacids.taurine.value"::text,
        v."aminoacids.taurine.unit"::text
    ) AS taurine_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."aminoacids.arginine.value"::text,
        v."aminoacids.arginine.unit"::text
    ) AS arginine_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."aminoacids.isoleucine.value"::text,
        v."aminoacids.isoleucine.unit"::text
    ) AS isoleucine_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."aminoacids.leucine.value"::text,
        v."aminoacids.leucine.unit"::text
    ) AS leucine_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."aminoacids.cystine.value"::text,
        v."aminoacids.cystine.unit"::text
    ) AS cystine_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."aminoacids.phenylalanine.value"::text,
        v."aminoacids.phenylalanine.unit"::text
    ) AS phenylalanine_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."aminoacids.tyrosine.value"::text,
        v."aminoacids.tyrosine.unit"::text
    ) AS tyrosine_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."aminoacids.threonine.value"::text,
        v."aminoacids.threonine.unit"::text
    ) AS threonine_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."aminoacids.tryptophan.value"::text,
        v."aminoacids.tryptophan.unit"::text
    ) AS tryptophan_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."aminoacids.valine.value"::text,
        v."aminoacids.valine.unit"::text
    ) AS valine_mg_kg,

    vet_analytics.convert_to_mg_kg(
        v."aminoacids.histidine.value"::text,
        v."aminoacids.histidine.unit"::text
    ) AS histidine_mg_kg,

    -- Choline
    vet_analytics.convert_to_mg_kg(
        v."nutrient.choline.value"::text,
        v."nutrient.choline.unit"::text
    ) AS choline_mg_kg,

    -- NFE
    vet_analytics.convert_to_mg_kg(
        v."nfe.value"::text,
        v."nfe.unit"::text
    ) AS nfe_mg_kg

FROM vet_analytics.vet_clean v;


$create_table$, v_b1_value, v_b1_unit);
END;
$check_and_create$;

COMMENT ON TABLE vet_analytics.vet_clean_mg_kg IS
    'Oksana normalization: all vet_clean source columns plus 49 numeric mg/kg columns. Rebuild after source changes.';
COMMIT;
