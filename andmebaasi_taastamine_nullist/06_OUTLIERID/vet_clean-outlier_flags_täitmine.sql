DO $$
DECLARE
    r RECORD;
    flag_column TEXT;
BEGIN

    FOR r IN
        SELECT DISTINCT column_name
        FROM vet_analytics.outliers
    LOOP

        IF r.column_name = 'convertible_energy' THEN
            flag_column := 'convertible_energy_flag';

        ELSIF r.column_name = 'ME_kcal' THEN
            flag_column := 'ME_kcal_flag';

        ELSE
            flag_column := r.column_name || '_flag';

        END IF;

        EXECUTE format(
            'UPDATE vet_analytics.vet_clean_outlier_flags v
             SET %I = o.flag
             FROM vet_analytics.outliers o
             WHERE v."_id" = o."_id"
               AND o.column_name = %L
               AND o.flag IS NOT NULL',
            flag_column,
            r.column_name
        );

    END LOOP;

END $$;