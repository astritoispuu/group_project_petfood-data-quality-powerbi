DROP TABLE IF EXISTS vet_analytics.vet_clean_outlier_flags;

DO $$
DECLARE
    col RECORD;
    select_sql TEXT := '';
    flag_name TEXT;
BEGIN

    FOR col IN
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'vet_analytics'
          AND table_name = 'vet_clean_mg_kg'
        ORDER BY ordinal_position
    LOOP

        -- Add the original column
        select_sql := select_sql ||
            format('v.%I', col.column_name);

        /*
         * Add flag immediately after every column
         * that exists in the outliers table.
         */
        IF EXISTS (
            SELECT 1
            FROM vet_analytics.outliers o
            WHERE
                o.column_name = col.column_name
                OR
                (
                    col.column_name = 'convertible_energy.value.1'
                    AND o.column_name = 'convertible_energy'
                )
                OR
                (
                    col.column_name = 'ME (kcal)'
                    AND o.column_name = 'ME_kcal'
                )
        ) THEN

            IF col.column_name = 'convertible_energy.value.1' THEN
                flag_name := 'convertible_energy_flag';

            ELSIF col.column_name = 'ME (kcal)' THEN
                flag_name := 'ME_kcal_flag';

            ELSE
                flag_name := col.column_name || '_flag';
            END IF;

            select_sql := select_sql ||
                format(', NULL::text AS %I', flag_name);

        END IF;

        select_sql := select_sql || ', ';

    END LOOP;

    -- Remove final comma
    select_sql := left(select_sql, length(select_sql) - 2);

    EXECUTE
        'CREATE TABLE vet_analytics.vet_clean_outlier_flags AS
         SELECT ' || select_sql || '
         FROM vet_analytics.vet_clean_mg_kg v';

END $$;