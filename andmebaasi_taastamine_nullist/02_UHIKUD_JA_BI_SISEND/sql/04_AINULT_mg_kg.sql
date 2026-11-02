-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 02_UHIKUD_JA_BI_SISEND | VERSIOON: 2026-10-05
-- AUTORLUS: Oksana – algne normaliseerimisloogika ja vastendused.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Original normalization logic and nutrient mappings: Oksana.
-- Compatibility review and documentation: 2026-10-05.
-- Existing BI workflow uses vet_clean_bi; do not create a parallel final table.
-- Preserve every source metadata column rather than a fixed 17-column list.
-- Remove raw .value/.valu/.unit columns; retain normalized _mg_kg columns.
-- No changes are made to vet_clean, vet_powerbi or ingredient tables.
BEGIN;

DO $create_bi$
DECLARE
    v_columns text;
    v_count integer;
BEGIN
    IF to_regclass('vet_analytics.vet_clean_mg_kg') IS NULL THEN
        RAISE EXCEPTION 'Run 02_create_normalized_table.sql first.';
    END IF;

    SELECT string_agg(format('%I', column_name), ', ' ORDER BY ordinal_position)
    INTO v_columns
    FROM information_schema.columns
    WHERE table_schema = 'vet_analytics' AND table_name = 'vet_clean_mg_kg'
      AND column_name !~* '\.(valu(e)?|unit)';

    SELECT count(*) INTO v_count
    FROM information_schema.columns
    WHERE table_schema = 'vet_analytics' AND table_name = 'vet_clean_mg_kg'
      AND right(column_name, 6) = '_mg_kg';
    IF v_count <> 49 OR v_columns IS NULL THEN
        RAISE EXCEPTION 'Expected 49 normalized columns; found %. Check step 02.', v_count;
    END IF;

    -- Transactional replacement. A dependency error stops without CASCADE.
    DROP TABLE IF EXISTS vet_analytics.vet_clean_bi;
    EXECUTE format(
        'CREATE TABLE vet_analytics.vet_clean_bi AS SELECT %s FROM vet_analytics.vet_clean_mg_kg',
        v_columns
    );
END;
$create_bi$;

COMMENT ON TABLE vet_analytics.vet_clean_bi IS
    'BI input based on Oksana normalization: metadata plus 49 mg/kg columns; raw .value/.unit fields excluded.';
COMMIT;

-- Row counts must match; final columns must not contain raw measurement fields.
SELECT (SELECT count(*) FROM vet_analytics.vet_clean) AS source_rows,
       (SELECT count(*) FROM vet_analytics.vet_clean_mg_kg) AS normalized_rows,
       (SELECT count(*) FROM vet_analytics.vet_clean_bi) AS bi_rows;

SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'vet_analytics' AND table_name = 'vet_clean_bi'
  AND column_name ~* '\.(valu(e)?|unit)';
-- Expected: zero rows.

SELECT * FROM vet_analytics.vet_clean_bi LIMIT 5;
