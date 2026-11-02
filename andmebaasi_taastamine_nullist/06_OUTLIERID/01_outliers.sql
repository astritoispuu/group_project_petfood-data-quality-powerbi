-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 06_OUTLIERID | VERSIOON: 2026-10-05
-- AUTORLUS: Liina – algne 51 näitaja IQR lahendus.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- ============================================================
-- outliersite_leidmine.sql
-- Statistical nutrient outliers using the 1.5 x IQR method
-- Original SQL author: Liina
-- Documentation and formatting update: 2026-10-05
-- Input:  vet_analytics.vet_clean_mg_kg
-- Output: vet_analytics.outliers (physical table)
-- Run after mg/kg normalization and validation.
-- All 51 indicators and the original calculation rules are retained.
-- ============================================================

-- ============================================================
-- 1. Recreate the results table
-- Only this derived table is dropped; source data is unchanged.
-- ============================================================
BEGIN;
DROP TABLE IF EXISTS vet_analytics.outliers;

CREATE TABLE vet_analytics.outliers AS
-- ============================================================
-- 2. Convert nutrient columns into individual measurement rows
-- 49 normalized mg/kg nutrients and 2 original energy fields.
-- Energy is analyzed separately by column_name; it is not mg/kg.
-- Preserve the existing NULLIF/TRIM/numeric expressions.
-- ============================================================
WITH measurements AS (
    SELECT
        v."_id",
        COALESCE(NULLIF(BTRIM(v.product_name_fi), ''),
                 NULLIF(BTRIM(v.product_name_en), ''), v._id::text) AS product_name,
        v.product_name_en,
        x.column_name,
        x.value
    FROM vet_analytics.vet_clean_mg_kg v
    CROSS JOIN LATERAL (
        VALUES
            ('crude_protein_mg_kg', NULLIF(TRIM(v.crude_protein_mg_kg::text), '')::numeric),
            ('digestible_protein_from_aa_mg_kg', NULLIF(TRIM(v.digestible_protein_from_aa_mg_kg::text), '')::numeric),
            ('crude_fat_mg_kg', NULLIF(TRIM(v.crude_fat_mg_kg::text), '')::numeric),
            ('crude_fibre_mg_kg', NULLIF(TRIM(v.crude_fibre_mg_kg::text), '')::numeric),
            ('ash_mg_kg', NULLIF(TRIM(v.ash_mg_kg::text), '')::numeric),

            ('vitamin_a_mg_kg', NULLIF(TRIM(v.vitamin_a_mg_kg::text), '')::numeric),
            ('vitamin_b1_mg_kg', NULLIF(TRIM(v.vitamin_b1_mg_kg::text), '')::numeric),
            ('vitamin_b2_mg_kg', NULLIF(TRIM(v.vitamin_b2_mg_kg::text), '')::numeric),
            ('vitamin_b6_mg_kg', NULLIF(TRIM(v.vitamin_b6_mg_kg::text), '')::numeric),
            ('vitamin_b12_mg_kg', NULLIF(TRIM(v.vitamin_b12_mg_kg::text), '')::numeric),
            ('vitamin_d3_mg_kg', NULLIF(TRIM(v.vitamin_d3_mg_kg::text), '')::numeric),
            ('vitamin_e_mg_kg', NULLIF(TRIM(v.vitamin_e_mg_kg::text), '')::numeric),
            ('pantothenic_acid_mg_kg', NULLIF(TRIM(v.pantothenic_acid_mg_kg::text), '')::numeric),
            ('niacin_mg_kg', NULLIF(TRIM(v.niacin_mg_kg::text), '')::numeric),
            ('folic_acid_mg_kg', NULLIF(TRIM(v.folic_acid_mg_kg::text), '')::numeric),
            ('biotin_mg_kg', NULLIF(TRIM(v.biotin_mg_kg::text), '')::numeric),
            ('vitamin_c_mg_kg', NULLIF(TRIM(v.vitamin_c_mg_kg::text), '')::numeric),
            ('vitamin_k_mg_kg', NULLIF(TRIM(v.vitamin_k_mg_kg::text), '')::numeric),

            ('fatty_acids_linoleic_acid_mg_kg', NULLIF(TRIM(v.fatty_acids_linoleic_acid_mg_kg::text), '')::numeric),
            ('vitamins_linoleic_acid_mg_kg', NULLIF(TRIM(v.vitamins_linoleic_acid_mg_kg::text), '')::numeric),

            ('iron_mg_kg', NULLIF(TRIM(v.iron_mg_kg::text), '')::numeric),
            ('zinc_mg_kg', NULLIF(TRIM(v.zinc_mg_kg::text), '')::numeric),
            ('copper_mg_kg', NULLIF(TRIM(v.copper_mg_kg::text), '')::numeric),
            ('copper_sulfate_mg_kg', NULLIF(TRIM(v.copper_sulfate_mg_kg::text), '')::numeric),
            ('calsium_mg_kg', NULLIF(TRIM(v.calsium_mg_kg::text), '')::numeric),
            ('phosphorous_mg_kg', NULLIF(TRIM(v.phosphorous_mg_kg::text), '')::numeric),
            ('magnesium_mg_kg', NULLIF(TRIM(v.magnesium_mg_kg::text), '')::numeric),
            ('sodium_mg_kg', NULLIF(TRIM(v.sodium_mg_kg::text), '')::numeric),
            ('potassium_mg_kg', NULLIF(TRIM(v.potassium_mg_kg::text), '')::numeric),
            ('iodine_mg_kg', NULLIF(TRIM(v.iodine_mg_kg::text), '')::numeric),
            ('manganese_mg_kg', NULLIF(TRIM(v.manganese_mg_kg::text), '')::numeric),
            ('selenium_mg_kg', NULLIF(TRIM(v.selenium_mg_kg::text), '')::numeric),
            ('cobalt_mg_kg', NULLIF(TRIM(v.cobalt_mg_kg::text), '')::numeric),
            ('natrium_mg_kg', NULLIF(TRIM(v.natrium_mg_kg::text), '')::numeric),

            ('lysine_mg_kg', NULLIF(TRIM(v.lysine_mg_kg::text), '')::numeric),
            ('methionine_mg_kg', NULLIF(TRIM(v.methionine_mg_kg::text), '')::numeric),
            ('taurine_mg_kg', NULLIF(TRIM(v.taurine_mg_kg::text), '')::numeric),
            ('arginine_mg_kg', NULLIF(TRIM(v.arginine_mg_kg::text), '')::numeric),
            ('isoleucine_mg_kg', NULLIF(TRIM(v.isoleucine_mg_kg::text), '')::numeric),
            ('leucine_mg_kg', NULLIF(TRIM(v.leucine_mg_kg::text), '')::numeric),
            ('cystine_mg_kg', NULLIF(TRIM(v.cystine_mg_kg::text), '')::numeric),
            ('phenylalanine_mg_kg', NULLIF(TRIM(v.phenylalanine_mg_kg::text), '')::numeric),
            ('tyrosine_mg_kg', NULLIF(TRIM(v.tyrosine_mg_kg::text), '')::numeric),
            ('threonine_mg_kg', NULLIF(TRIM(v.threonine_mg_kg::text), '')::numeric),
            ('tryptophan_mg_kg', NULLIF(TRIM(v.tryptophan_mg_kg::text), '')::numeric),
            ('valine_mg_kg', NULLIF(TRIM(v.valine_mg_kg::text), '')::numeric),
            ('histidine_mg_kg', NULLIF(TRIM(v.histidine_mg_kg::text), '')::numeric),
            ('choline_mg_kg', NULLIF(TRIM(v.choline_mg_kg::text), '')::numeric),

            ('nfe_mg_kg', NULLIF(TRIM(v.nfe_mg_kg::text), '')::numeric),

            -- Original energy fields: no conversion or unit validation here.
            -- Review their source units before interpreting these results.
            ('convertible_energy', NULLIF(TRIM(v."convertible_energy.value.1"::text), '')::numeric),
            ('ME_kcal', NULLIF(TRIM(v."ME (kcal)"::text), '')::numeric)
    ) AS x(column_name, value)
),

-- ============================================================
-- 3. Calculate Q1 and Q3 separately for each indicator
-- Exclude missing values and zero, preserving the original rule.
-- ============================================================
statistics AS (
    SELECT
        column_name,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY value) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY value) AS q3
    FROM measurements
    WHERE value IS NOT NULL
      AND value <> 0
    GROUP BY column_name
)

-- ============================================================
-- 4. Calculate IQR bounds and save only statistical outliers
-- Lower bound: Q1 - 1.5 * IQR (not clamped to zero).
-- Upper bound: Q3 + 1.5 * IQR.
-- Equality with a bound is not an outlier.
-- ============================================================
SELECT
    m."_id",
    m.product_name,
    m.product_name_en,
    m.column_name,
    m.value,
    s.q1,
    s.q3,
    s.q3 - s.q1 AS iqr,
    s.q1 - 1.5 * (s.q3 - s.q1) AS lower_bound,
    s.q3 + 1.5 * (s.q3 - s.q1) AS upper_bound,
    CASE
        WHEN m.value < s.q1 - 1.5 * (s.q3 - s.q1)
            THEN 'LOW_OUTLIER'
        WHEN m.value > s.q3 + 1.5 * (s.q3 - s.q1)
            THEN 'HIGH_OUTLIER'
    END AS flag
FROM measurements m
JOIN statistics s
    ON s.column_name = m.column_name
WHERE m.value IS NOT NULL
  AND m.value <> 0
  AND (
        m.value < s.q1 - 1.5 * (s.q3 - s.q1)
        OR
        m.value > s.q3 + 1.5 * (s.q3 - s.q1)
      )
ORDER BY
    m.column_name,
    m.value DESC;

COMMIT;
