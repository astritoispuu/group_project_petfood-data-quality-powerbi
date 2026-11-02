-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 02_UHIKUD_JA_BI_SISEND | VERSIOON: 2026-10-05
-- AUTORLUS: Oksana – algne normaliseerimisloogika ja vastendused.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Original normalization logic and nutrient mappings: Oksana.
-- Compatibility review and documentation: 2026-10-05.
-- Optional function checks; run after 01. Every row must show passed = true.
WITH checks AS (
    SELECT * FROM (VALUES
        ('mg_identity', vet_analytics.convert_to_mg_kg('20', 'mg/kg'), 20::numeric),
        ('standalone_mg_assumption', vet_analytics.convert_to_mg_kg('20', 'mg'), 20::numeric),
        ('grams', vet_analytics.convert_to_mg_kg('2.5', 'g/kg'), 2500::numeric),
        ('decimal_comma', vet_analytics.convert_to_mg_kg('2,5', 'g/kg'), 2500::numeric),
        ('percent', vet_analytics.convert_to_mg_kg('1', '%'), 10000::numeric),
        ('micrograms', vet_analytics.convert_to_mg_kg('0.6', 'µg/kg'), 0.0006::numeric),
        ('greek_mu', vet_analytics.convert_to_mg_kg('0.6', 'μg'), 0.0006::numeric),
        ('ascii_ug', vet_analytics.convert_to_mg_kg('0.6', 'ug'), 0.0006::numeric),
        ('case_and_trim', vet_analytics.convert_to_mg_kg(' 2.5 ', ' G/KG '), 2500::numeric),
        ('zero_is_preserved', vet_analytics.convert_to_mg_kg('0', 'mg/kg'), 0::numeric),
        ('unicode_minus', vet_analytics.convert_to_mg_kg('−2', 'mg/kg'), -2::numeric),
        ('empty', vet_analytics.convert_to_mg_kg('', 'mg/kg'), NULL::numeric),
        ('invalid', vet_analytics.convert_to_mg_kg('106..66', 'mg/kg'), NULL::numeric),
        ('nonfinite', vet_analytics.convert_to_mg_kg('NaN', 'mg/kg'), NULL::numeric),
        ('unknown_unit', vet_analytics.convert_to_mg_kg('10', 'mg/100g'), NULL::numeric),
        ('energy', vet_analytics.convert_to_mg_kg('10', 'kcal'), NULL::numeric),
        ('empty_unit', vet_analytics.convert_to_mg_kg('10', ''), NULL::numeric),
        ('a_retinol_equivalent', vet_analytics.convert_vitamin_to_mg_kg('24000', 'IE', 'a'), 7.2::numeric),
        ('d3_precision', vet_analytics.convert_vitamin_to_mg_kg('1', 'IU', 'd3'), 0.000025::numeric),
        ('e_feed_acetate', vet_analytics.convert_vitamin_to_mg_kg('200', 'IU', 'e'), 200::numeric),
        ('unsupported_vitamin_iu', vet_analytics.convert_vitamin_to_mg_kg('10', 'IU', 'b1'), NULL::numeric),
        ('vitamin_mass_unit', vet_analytics.convert_vitamin_to_mg_kg('2', 'g/kg', 'a'), 2000::numeric)
    ) AS t(check_name, actual, expected)
)
SELECT *, actual IS NOT DISTINCT FROM expected AS passed
FROM checks
ORDER BY check_name;
