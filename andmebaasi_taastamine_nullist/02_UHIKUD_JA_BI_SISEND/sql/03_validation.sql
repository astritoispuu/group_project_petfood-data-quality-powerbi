-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 02_UHIKUD_JA_BI_SISEND | VERSIOON: 2026-10-05
-- AUTORLUS: Oksana – algne normaliseerimisloogika ja vastendused.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Original normalization logic and nutrient mappings: Oksana.
-- Compatibility review and documentation: 2026-10-05.
-- Run after 02. Temporary review rows exist only in this database session.
-- No persistent table data are changed.
SELECT (SELECT count(*) FROM vet_analytics.vet_clean) AS source_rows,
       (SELECT count(*) FROM vet_analytics.vet_clean_mg_kg) AS normalized_rows;

DO $review$
DECLARE
    v_b1_value text;
    v_b1_unit text;
    v_count integer;
BEGIN
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

    DROP TABLE IF EXISTS pg_temp.normalization_review;
    EXECUTE format($review_query$
CREATE TEMP TABLE normalization_review AS
SELECT v._id AS product_id,
       n.nutrient, n.original_value, n.original_unit, n.normalized_value
FROM vet_analytics.vet_clean_mg_kg v
CROSS JOIN LATERAL (VALUES
    ('crude_protein_mg_kg', v."proteins.crude_protein.value"::text, v."proteins.crude_protein.unit"::text, v.crude_protein_mg_kg),
    ('digestible_protein_from_aa_mg_kg', v."proteins.digestible_protein_from_AA.value"::text, v."proteins.digestible_protein_from_AA.unit"::text, v.digestible_protein_from_aa_mg_kg),
    ('crude_fat_mg_kg', v."crude_fat.value"::text, v."crude_fat.unit"::text, v.crude_fat_mg_kg),
    ('crude_fibre_mg_kg', v."crude_fibre.value"::text, v."crude_fibre.unit"::text, v.crude_fibre_mg_kg),
    ('ash_mg_kg', v."ash.value"::text, v."ash.unit"::text, v.ash_mg_kg),
    ('vitamin_a_mg_kg', v."vitamins.a_vitamin.value"::text, v."vitamins.a_vitamin.unit"::text, v.vitamin_a_mg_kg),
    ('vitamin_b1_mg_kg', v.%1$I::text, v.%2$I::text, v.vitamin_b1_mg_kg),
    ('vitamin_b2_mg_kg', v."vitamins.b2_vitamin.value"::text, v."vitamins.b2_vitamin.unit"::text, v.vitamin_b2_mg_kg),
    ('vitamin_b6_mg_kg', v."vitamins.b6_vitamin.value"::text, v."vitamins.b6_vitamin.unit"::text, v.vitamin_b6_mg_kg),
    ('vitamin_b12_mg_kg', v."vitamins.b12_vitamin.value"::text, v."vitamins.b12_vitamin.unit"::text, v.vitamin_b12_mg_kg),
    ('vitamin_d3_mg_kg', v."vitamins.d3_vitamin.value"::text, v."vitamins.d3_vitamin.unit"::text, v.vitamin_d3_mg_kg),
    ('vitamin_e_mg_kg', v."vitamins.e_vitamin.value"::text, v."vitamins.e_vitamin.unit"::text, v.vitamin_e_mg_kg),
    ('pantothenic_acid_mg_kg', v."vitamins.pantothenic_acid.value"::text, v."vitamins.pantothenic_acid.unit"::text, v.pantothenic_acid_mg_kg),
    ('niacin_mg_kg', v."vitamins.niacin.value"::text, v."vitamins.niacin.unit"::text, v.niacin_mg_kg),
    ('folic_acid_mg_kg', v."vitamins.folic_acid.value"::text, v."vitamins.folic_acid.unit"::text, v.folic_acid_mg_kg),
    ('biotin_mg_kg', v."vitamins.biotin.value"::text, v."vitamins.biotin.unit"::text, v.biotin_mg_kg),
    ('vitamin_c_mg_kg', v."vitamins.c_vitamin.value"::text, v."vitamins.c_vitamin.unit"::text, v.vitamin_c_mg_kg),
    ('vitamin_k_mg_kg', v."vitamins.k_vitamin.value"::text, v."vitamins.k_vitamin.unit"::text, v.vitamin_k_mg_kg),
    ('fatty_acids_linoleic_acid_mg_kg', v."fatty_acids.linoleic_acid.value"::text, v."fatty_acids.linoleic_acid.unit"::text, v.fatty_acids_linoleic_acid_mg_kg),
    ('vitamins_linoleic_acid_mg_kg', v."vitamins.linoleic_acid.value"::text, v."vitamins.linoleic_acid.unit"::text, v.vitamins_linoleic_acid_mg_kg),
    ('iron_mg_kg', v."trace_elements.iron.value"::text, v."trace_elements.iron.unit"::text, v.iron_mg_kg),
    ('zinc_mg_kg', v."trace_elements.zinc.value"::text, v."trace_elements.zinc.unit"::text, v.zinc_mg_kg),
    ('copper_mg_kg', v."trace_elements.copper.value"::text, v."trace_elements.copper.unit"::text, v.copper_mg_kg),
    ('copper_sulfate_mg_kg', v."trace_elements.copper_sulfate.value"::text, v."trace_elements.copper_sulfate.unit"::text, v.copper_sulfate_mg_kg),
    ('calsium_mg_kg', v."minerals.calsium.value"::text, v."minerals.calsium.unit"::text, v.calsium_mg_kg),
    ('phosphorous_mg_kg', v."minerals.phosphorous.value"::text, v."minerals.phosphorous.unit"::text, v.phosphorous_mg_kg),
    ('magnesium_mg_kg', v."minerals.magnesium.value"::text, v."minerals.magnesium.unit"::text, v.magnesium_mg_kg),
    ('sodium_mg_kg', v."minerals.sodium.value"::text, v."minerals.sodium.unit"::text, v.sodium_mg_kg),
    ('potassium_mg_kg', v."minerals.potassium.value"::text, v."minerals.potassium.unit"::text, v.potassium_mg_kg),
    ('iodine_mg_kg', v."minerals.iodine.value"::text, v."minerals.iodine.unit"::text, v.iodine_mg_kg),
    ('manganese_mg_kg', v."minerals.manganese.value"::text, v."minerals.manganese.unit"::text, v.manganese_mg_kg),
    ('selenium_mg_kg', v."minerals.selenium.value"::text, v."minerals.selenium.unit"::text, v.selenium_mg_kg),
    ('cobalt_mg_kg', v."minerals.cobalt.value"::text, v."minerals.cobalt.unit"::text, v.cobalt_mg_kg),
    ('natrium_mg_kg', v."minerals.natrium.value"::text, v."minerals.natrium.unit"::text, v.natrium_mg_kg),
    ('lysine_mg_kg', v."aminoacids.lysine.value"::text, v."aminoacids.lysine.unit"::text, v.lysine_mg_kg),
    ('methionine_mg_kg', v."aminoacids.methionine.value"::text, v."aminoacids.methionine.unit"::text, v.methionine_mg_kg),
    ('taurine_mg_kg', v."aminoacids.taurine.value"::text, v."aminoacids.taurine.unit"::text, v.taurine_mg_kg),
    ('arginine_mg_kg', v."aminoacids.arginine.value"::text, v."aminoacids.arginine.unit"::text, v.arginine_mg_kg),
    ('isoleucine_mg_kg', v."aminoacids.isoleucine.value"::text, v."aminoacids.isoleucine.unit"::text, v.isoleucine_mg_kg),
    ('leucine_mg_kg', v."aminoacids.leucine.value"::text, v."aminoacids.leucine.unit"::text, v.leucine_mg_kg),
    ('cystine_mg_kg', v."aminoacids.cystine.value"::text, v."aminoacids.cystine.unit"::text, v.cystine_mg_kg),
    ('phenylalanine_mg_kg', v."aminoacids.phenylalanine.value"::text, v."aminoacids.phenylalanine.unit"::text, v.phenylalanine_mg_kg),
    ('tyrosine_mg_kg', v."aminoacids.tyrosine.value"::text, v."aminoacids.tyrosine.unit"::text, v.tyrosine_mg_kg),
    ('threonine_mg_kg', v."aminoacids.threonine.value"::text, v."aminoacids.threonine.unit"::text, v.threonine_mg_kg),
    ('tryptophan_mg_kg', v."aminoacids.tryptophan.value"::text, v."aminoacids.tryptophan.unit"::text, v.tryptophan_mg_kg),
    ('valine_mg_kg', v."aminoacids.valine.value"::text, v."aminoacids.valine.unit"::text, v.valine_mg_kg),
    ('histidine_mg_kg', v."aminoacids.histidine.value"::text, v."aminoacids.histidine.unit"::text, v.histidine_mg_kg),
    ('choline_mg_kg', v."nutrient.choline.value"::text, v."nutrient.choline.unit"::text, v.choline_mg_kg),
    ('nfe_mg_kg', v."nfe.value"::text, v."nfe.unit"::text, v.nfe_mg_kg)
) AS n(nutrient, original_value, original_unit, normalized_value)
$review_query$, v_b1_value, v_b1_unit);
END;
$review$;

-- Coverage distinguishes missing input from failed/unsupported conversions.
SELECT nutrient,
       count(*) AS product_rows,
       count(*) FILTER (WHERE NULLIF(btrim(original_value), '') IS NOT NULL) AS populated_inputs,
       count(normalized_value) AS converted_values,
       count(*) FILTER (WHERE NULLIF(btrim(original_value), '') IS NOT NULL
                        AND normalized_value IS NULL) AS unconverted_inputs,
       count(*) FILTER (WHERE normalized_value < 0) AS negative_values,
       min(normalized_value) AS minimum_mg_kg,
       max(normalized_value) AS maximum_mg_kg
FROM normalization_review
GROUP BY nutrient
ORDER BY nutrient;

-- Review actual losses instead of running repeated unit-frequency queries.
SELECT nutrient, original_unit, original_value, count(*) AS occurrences
FROM normalization_review
WHERE NULLIF(btrim(original_value), '') IS NOT NULL
  AND normalized_value IS NULL
GROUP BY nutrient, original_unit, original_value
ORDER BY occurrences DESC, nutrient
LIMIT 200;

-- Inspect negative outputs; flag them instead of changing source values.
SELECT * FROM normalization_review
WHERE normalized_value < 0
ORDER BY nutrient, product_id
LIMIT 100;

-- Standalone units need confirmation that the label basis is one kg.
SELECT nutrient, original_unit, count(*) AS populated_inputs
FROM normalization_review
WHERE NULLIF(btrim(original_value), '') IS NOT NULL
  AND lower(btrim(coalesce(original_unit, ''))) IN ('mg', 'g', 'µg', 'μg', 'ug', 'mcg', 'iu', 'ie')
GROUP BY nutrient, original_unit
ORDER BY nutrient, original_unit;

-- E's factor x1 is retained. Verify the feed additive form in the source label.
SELECT product_id, original_value, original_unit, normalized_value
FROM normalization_review
WHERE nutrient = 'vitamin_e_mg_kg'
  AND lower(btrim(coalesce(original_unit, ''))) IN ('iu', 'ie')
ORDER BY product_id
LIMIT 100;

-- Detect nutrient pairs with no mapping in Oksana's selected 49 columns.
-- Energy is expected here and must not be converted into mass concentration.
SELECT column_name AS unmapped_source_value_column
FROM information_schema.columns
WHERE table_schema = 'vet_analytics' AND table_name = 'vet_clean'
  AND column_name ~* '\.value$'
  AND column_name <> ALL(ARRAY['proteins.crude_protein.value', 'proteins.digestible_protein_from_AA.value', 'crude_fat.value', 'crude_fibre.value', 'ash.value', 'vitamins.a_vitamin.value', 'vitamins..b1_vitamin.value', 'vitamins.b2_vitamin.value', 'vitamins.b6_vitamin.value', 'vitamins.b12_vitamin.value', 'vitamins.d3_vitamin.value', 'vitamins.e_vitamin.value', 'vitamins.pantothenic_acid.value', 'vitamins.niacin.value', 'vitamins.folic_acid.value', 'vitamins.biotin.value', 'vitamins.c_vitamin.value', 'vitamins.k_vitamin.value', 'fatty_acids.linoleic_acid.value', 'vitamins.linoleic_acid.value', 'trace_elements.iron.value', 'trace_elements.zinc.value', 'trace_elements.copper.value', 'trace_elements.copper_sulfate.value', 'minerals.calsium.value', 'minerals.phosphorous.value', 'minerals.magnesium.value', 'minerals.sodium.value', 'minerals.potassium.value', 'minerals.iodine.value', 'minerals.manganese.value', 'minerals.selenium.value', 'minerals.cobalt.value', 'minerals.natrium.value', 'aminoacids.lysine.value', 'aminoacids.methionine.value', 'aminoacids.taurine.value', 'aminoacids.arginine.value', 'aminoacids.isoleucine.value', 'aminoacids.leucine.value', 'aminoacids.cystine.value', 'aminoacids.phenylalanine.value', 'aminoacids.tyrosine.value', 'aminoacids.threonine.value', 'aminoacids.tryptophan.value', 'aminoacids.valine.value', 'aminoacids.histidine.value', 'nutrient.choline.value', 'nfe.value', 'vitamins.b1_vitamin.value']::text[])
ORDER BY column_name;

-- Precision is unrestricted numeric. No rounding to three decimals is applied.
SELECT column_name, data_type, numeric_precision, numeric_scale
FROM information_schema.columns
WHERE table_schema = 'vet_analytics' AND table_name = 'vet_clean_mg_kg'
  AND right(column_name, 6) = '_mg_kg'
ORDER BY ordinal_position;
