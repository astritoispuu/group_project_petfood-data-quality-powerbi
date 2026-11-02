-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 05_POWER_BI_ANDMEMUDEL | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Fail: 002_loo_vet_powerbi_mudel.sql | Uuendus 05.10.2026.
-- Algsest 05.10 mudeli loomisskriptist kohandatud taastamise tervikjärjekorrale.
-- Sisend: vet_analytics.vet_clean_bi ja Liina loodud vet_powerbi.fact_ingredients.
-- Käivita pärast 04_KOOSTISOSADE_KATEGORISEERIMINE etappi.
-- Loob neli dim/toitainefakti tabelit; olemasolev koostisosafakt säilib.
-- Järgmiseks 003_taienda_dim_ingredients.sql ja 004_kontrolli_mudelit.sql.
-- Kogu DO-plokk on tehinguline: vea korral mudeli osalist tulemust ei jää.
-- Originaalskripti nimeline autor ei ole paketi allikas märgitud.
-- Käivitamine ja tulemused: README.md ning 00_JUHEND_JA_LOGI.

DO $model$
DECLARE
    source_table regclass := to_regclass('vet_analytics.vet_clean_bi');
    ingredient_table regclass := to_regclass('vet_powerbi.fact_ingredients');
    product_columns text;
    nutrient_values text;
    source_count bigint;
    ingredient_count bigint;
    nutrient_count bigint;
BEGIN
    -- 002.01. Veendume, et mõlemad kasutaja määratud lähtetabelid on olemas.
    IF source_table IS NULL OR ingredient_table IS NULL THEN
        RAISE EXCEPTION 'Puudub vet_analytics.vet_clean_bi või vet_powerbi.fact_ingredients. Mudelit ei loodud.';
    END IF;

    -- Hoiame lähteandmed kogu loomise ajal samas seisus.
    LOCK TABLE vet_analytics.vet_clean_bi IN SHARE MODE;
    LOCK TABLE vet_powerbi.fact_ingredients IN SHARE MODE;

    IF NOT EXISTS (SELECT 1 FROM pg_attribute
                   WHERE attrelid = source_table AND attname = '_id'
                     AND attnum > 0 AND NOT attisdropped)
       OR NOT EXISTS (SELECT 1 FROM pg_attribute
                      WHERE attrelid = ingredient_table AND attname = 'product_id'
                        AND attnum > 0 AND NOT attisdropped)
       OR NOT EXISTS (SELECT 1 FROM pg_attribute
                      WHERE attrelid = ingredient_table AND attname = 'ingredient'
                        AND attnum > 0 AND NOT attisdropped) THEN
        RAISE EXCEPTION 'Toodete tabel vajab _id veergu; koostisosade tabel vajab product_id ja ingredient veerge.';
    END IF;

    -- Sihtskeem võib juba eelmise sammu järel olemas olla.
    CREATE SCHEMA IF NOT EXISTS vet_powerbi;
    IF EXISTS (
        SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'vet_powerbi' AND c.relname IN (
            'dim_products', 'dim_nutrients', 'dim_ingredients',
            'fact_product_nutrients', 'fact_product_ingredients'
        )
    ) THEN
        RAISE EXCEPTION 'vet_powerbi sisaldab juba mudeli objekte. Skript on mõeldud tühja skeemi jaoks; midagi ei kustutatud.';
    END IF;

    -- 002.02. Leiame päris veerunimed automaatselt, ilma päiseid muutmata.
    -- Toitaineteks loeme veerud, mille nimes on _mg_kg.
    -- Vanad .valu/.value/.unit väljad ei pääse kumbagi mudelitabelisse.
    CREATE TEMP TABLE _vet_bi_columns ON COMMIT DROP AS
    SELECT attnum AS column_order, attname::text AS column_name,
           position('_mg_kg' IN lower(attname::text)) > 0 AS is_nutrient
    FROM pg_attribute
    WHERE attrelid = source_table AND attnum > 0 AND NOT attisdropped
      AND attname::text !~* '[.][[:space:]]*(valu|unit)';

    SELECT COUNT(*) INTO nutrient_count FROM _vet_bi_columns WHERE is_nutrient;
    IF nutrient_count = 0 THEN
        RAISE EXCEPTION 'vet_clean_bi tabelis ei leitud _mg_kg veerge. Kontrolli tegelikke veerunimesid; ühikuid ei oletata.';
    END IF;
    IF EXISTS (SELECT 1 FROM _vet_bi_columns WHERE column_name = 'product_id') THEN
        RAISE EXCEPTION 'Allikas sisaldab juba product_id veergu. _id ümbernimetamine tekitaks nimekorduse.';
    END IF;

    -- 002.03. Kontrollime Power BI seoste jaoks vajalikke võtmeid.
    SELECT COUNT(*) INTO source_count FROM vet_analytics.vet_clean_bi;
    SELECT COUNT(*) INTO ingredient_count FROM vet_powerbi.fact_ingredients;
    IF source_count = 0 OR ingredient_count = 0 THEN
        RAISE EXCEPTION 'Toodete või koostisosade lähtetabel on tühi. Käivita esmalt etapid 01–04.';
    END IF;
    IF EXISTS (SELECT 1 FROM vet_analytics.vet_clean_bi
               WHERE NULLIF(BTRIM(_id::text), '') IS NULL)
       OR EXISTS (SELECT 1 FROM vet_analytics.vet_clean_bi
                  GROUP BY lower(_id::text) HAVING COUNT(*) > 1) THEN
        RAISE EXCEPTION 'vet_clean_bi sisaldab tühja või korduvat _id väärtust. Kontroll arvestab ka suur-/väiketähe erinevust.';
    END IF;
    IF EXISTS (SELECT 1 FROM vet_powerbi.fact_ingredients
               WHERE NULLIF(BTRIM(ingredient::text), '') IS NULL) THEN
        RAISE EXCEPTION 'fact_ingredients sisaldab tühja koostisosanime. Lähtetabelit ei muudeta.';
    END IF;
    IF EXISTS (SELECT 1 FROM vet_powerbi.fact_ingredients
               GROUP BY lower(ingredient::text)
               HAVING COUNT(DISTINCT ingredient::text) > 1) THEN
        RAISE EXCEPTION 'Koostisosanimes on ainult suur-/väiketähe poolest erinevaid variante. Power BI üks-pool vajab üheselt eristatavaid nimesid.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM vet_powerbi.fact_ingredients f
        WHERE NOT EXISTS (SELECT 1 FROM vet_analytics.vet_clean_bi v
                          WHERE v._id::text = f.product_id::text)
    ) THEN
        RAISE EXCEPTION 'fact_ingredients sisaldab toote _id väärtust, mida vet_clean_bi tabelis pole. Ühtegi koostisosarida ei eemaldatud.';
    END IF;

    -- 002.04. Toodete dimensioon: üks rida iga toote kohta.
    -- _id saab nime product_id; kõik muud lubatud mittetoitaineveerud jäävad
    -- alles oma algsete nimede, tüüpide ja väärtustega (sh energia jms väljad).
    SELECT string_agg(format('v.%I', column_name), ', ' ORDER BY column_order)
    INTO product_columns FROM _vet_bi_columns
    WHERE NOT is_nutrient AND column_name <> '_id';

    EXECUTE 'CREATE TABLE vet_powerbi.dim_products AS SELECT '
        || 'v._id::text AS product_id'
        || CASE WHEN product_columns IS NULL THEN '' ELSE ', ' || product_columns END
        || CASE WHEN EXISTS (SELECT 1 FROM _vet_bi_columns WHERE column_name='product_name')
                THEN '' ELSE ', COALESCE(NULLIF(BTRIM(v.product_name_fi), ), NULLIF(BTRIM(v.product_name_en), ), v._id::text) AS product_name' END
        || ' FROM vet_analytics.vet_clean_bi v';
    ALTER TABLE vet_powerbi.dim_products ADD PRIMARY KEY (product_id);

    -- 002.05. Toitainete dimensioon: üks rida iga _mg_kg lähteveeru kohta.
    CREATE TABLE vet_powerbi.dim_nutrients AS
    SELECT row_number() OVER (ORDER BY column_order)::integer AS nutrient_id,
           column_name AS nutrient_name, 'mg/kg'::text AS unit
    FROM _vet_bi_columns WHERE is_nutrient;
    ALTER TABLE vet_powerbi.dim_nutrients ADD PRIMARY KEY (nutrient_id);
    ALTER TABLE vet_powerbi.dim_nutrients ADD UNIQUE (nutrient_name);

    -- 002.06. Toitainete fakt: üks rida iga toote ja toitaine kombinatsiooni kohta.
    -- Ühikuid uuesti ei teisendata. Numeric säilitab täpsuse, NULL ja 0 eristuvad.
    -- Vigane mittetühi arv peatab loomise; seda ei asendata NULL-iga.
    SELECT string_agg(
        format('(%s, NULLIF(BTRIM(v.%I::text), '''')::numeric)', nutrient_id, nutrient_name),
        ', ' ORDER BY nutrient_id)
    INTO nutrient_values FROM vet_powerbi.dim_nutrients;

    EXECUTE 'CREATE TABLE vet_powerbi.fact_product_nutrients AS '
        || 'SELECT v._id::text AS product_id, x.nutrient_id, x.value_mg_kg '
        || 'FROM vet_analytics.vet_clean_bi v CROSS JOIN LATERAL (VALUES '
        || nutrient_values || ') AS x(nutrient_id, value_mg_kg)';
    ALTER TABLE vet_powerbi.fact_product_nutrients ADD PRIMARY KEY (product_id, nutrient_id);
    ALTER TABLE vet_powerbi.fact_product_nutrients
        ADD FOREIGN KEY (product_id) REFERENCES vet_powerbi.dim_products(product_id),
        ADD FOREIGN KEY (nutrient_id) REFERENCES vet_powerbi.dim_nutrients(nutrient_id);
    CREATE INDEX ON vet_powerbi.fact_product_nutrients (nutrient_id);

    -- 002.07. Koostisosade dimensioon kasutab olemasolevat ingredient veergu.
    -- Koostisosanimesid ei puhastata, tõlgita ega muudeta. Koostisosafakt on juba Liina skriptiga loodud.
    CREATE TABLE vet_powerbi.dim_ingredients AS
    SELECT DISTINCT ingredient FROM vet_powerbi.fact_ingredients;
    ALTER TABLE vet_powerbi.dim_ingredients ADD PRIMARY KEY (ingredient);

    -- Koostisosafakt on juba vet_powerbi skeemis, product_id võtmega.
    -- Tabelit ei liigutata, nimetata ümber ega kirjutata üle.

    -- 002.09. Kontrollime mahtu ja koostisosafakti säilimist.
    IF (SELECT COUNT(*) FROM vet_powerbi.dim_products) <> source_count
       OR (SELECT COUNT(*) FROM vet_powerbi.fact_product_nutrients)
          <> source_count * nutrient_count
       OR (SELECT COUNT(*) FROM vet_powerbi.fact_ingredients) <> ingredient_count
       OR to_regclass('vet_powerbi.fact_ingredients') <> ingredient_table THEN
        RAISE EXCEPTION 'Mudeli lõppkontroll ebaõnnestus. Kõik selle käsu muudatused tühistatakse.';
    END IF;

    RAISE NOTICE 'Mudel loodud: % toodet, % toitainet, % toitainefakti rida, % koostisosafakti rida.',
        source_count, nutrient_count, source_count * nutrient_count, ingredient_count;
END
$model$;

-- 002.10. Lõpptulemus: allolev päring peab kuvama viis tabelit ja nende rea-arvud.
SELECT 'dim_products' AS table_name, COUNT(*) AS row_count FROM vet_powerbi.dim_products
UNION ALL SELECT 'dim_nutrients', COUNT(*) FROM vet_powerbi.dim_nutrients
UNION ALL SELECT 'dim_ingredients', COUNT(*) FROM vet_powerbi.dim_ingredients
UNION ALL SELECT 'fact_product_nutrients', COUNT(*) FROM vet_powerbi.fact_product_nutrients
UNION ALL SELECT 'fact_ingredients', COUNT(*) FROM vet_powerbi.fact_ingredients;
