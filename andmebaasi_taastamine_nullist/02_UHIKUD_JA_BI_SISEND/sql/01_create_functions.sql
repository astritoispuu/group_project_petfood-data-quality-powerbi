-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 02_UHIKUD_JA_BI_SISEND | VERSIOON: 2026-10-05
-- AUTORLUS: Oksana – algne normaliseerimisloogika ja vastendused.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Original normalization logic and nutrient mappings: Oksana.
-- Compatibility review and documentation: 2026-10-05.
BEGIN;

CREATE OR REPLACE FUNCTION vet_analytics.convert_to_mg_kg(p_value text, p_unit text)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
    v_value numeric;
    v_unit text;
    v_clean_value text;
BEGIN
    -- Return NULL for a missing or empty value.
    IF NULLIF(TRIM(p_value), '') IS NULL THEN
        RETURN NULL;
    END IF;

    -- Normalize the input value.
    v_clean_value := TRIM(p_value);

    -- Normalize Unicode minus signs.
    v_clean_value := REPLACE(v_clean_value, '−', '-');
    v_clean_value := REPLACE(v_clean_value, '–', '-');
    v_clean_value := REPLACE(v_clean_value, '—', '-');

    -- Convert decimal commas to decimal points.
    v_clean_value := REPLACE(v_clean_value, ',', '.');

    -- Try converting the value to numeric.
    -- Return NULL if the value is invalid.
    BEGIN
        v_value := v_clean_value::numeric;
    EXCEPTION
        WHEN invalid_text_representation OR numeric_value_out_of_range THEN
            RETURN NULL;
    END;

    -- PostgreSQL numeric also accepts NaN and Infinity; these are not nutrients.
    IF v_value::text IN ('NaN', 'Infinity', '-Infinity') THEN
        RETURN NULL;
    END IF;

    v_unit := LOWER(TRIM(COALESCE(p_unit, '')));

    CASE v_unit

        -- Standalone mg/g/microgram units retain Oksana's per-kg assumption.
        -- See README: mass alone does not establish a concentration.
        -- mg/kg
        WHEN 'mg/kg', 'mg na kg', 'mg' THEN
            RETURN v_value;

        -- g/kg
        WHEN 'g/kg', 'g na kg', 'g' THEN
            RETURN v_value * 1000;

        -- µg/kg
        WHEN 'µg/kg', 'μg/kg', 'ug/kg', 'mcg/kg' THEN
            RETURN v_value * 0.001;

        -- µg
        WHEN 'µg', 'μg', 'ug', 'mcg' THEN
            RETURN v_value * 0.001;

        -- %
        WHEN '%' THEN
            RETURN v_value * 10000;

        -- Return NULL for an unsupported unit.
        ELSE
            RETURN NULL;

    END CASE;
END;
$function$;


CREATE OR REPLACE FUNCTION vet_analytics.convert_vitamin_to_mg_kg(p_value text, p_unit text, p_vitamin text)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
    v_unit text;
    v_value numeric;
    v_clean_value text;
BEGIN
    IF NULLIF(TRIM(p_value), '') IS NULL THEN
        RETURN NULL;
    END IF;

    v_clean_value := TRIM(p_value);

    -- Normalize Unicode minus signs.
    v_clean_value := REPLACE(v_clean_value, '−', '-');
    v_clean_value := REPLACE(v_clean_value, '–', '-');
    v_clean_value := REPLACE(v_clean_value, '—', '-');

    -- Convert decimal commas to decimal points.
    v_clean_value := REPLACE(v_clean_value, ',', '.');

    BEGIN
        v_value := v_clean_value::numeric;
    EXCEPTION
        WHEN invalid_text_representation OR numeric_value_out_of_range THEN
            RETURN NULL;
    END;

    -- PostgreSQL numeric also accepts NaN and Infinity; these are not nutrients.
    IF v_value::text IN ('NaN', 'Infinity', '-Infinity') THEN
        RETURN NULL;
    END IF;

    v_unit := LOWER(TRIM(COALESCE(p_unit, '')));

    IF v_unit IN ('iu', 'ie') THEN

        CASE LOWER(TRIM(p_vitamin))

            -- A is expressed as retinol-equivalent mass, not ester mass.
            WHEN 'a' THEN
                RETURN v_value * 0.0003;

            WHEN 'd3' THEN
                RETURN v_value * 0.000025;

            -- Feed convention: all-rac-alpha-tocopheryl acetate.
            -- 1 IU = 1 mg of this form; not a universal vitamin E factor.
            WHEN 'e' THEN
                RETURN v_value;

            ELSE
                RETURN NULL;

        END CASE;

    END IF;

    RETURN vet_analytics.convert_to_mg_kg(p_value, p_unit);
END;
$function$;

COMMIT;
