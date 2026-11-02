-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 07_LOPPKONTROLL | VERSIOON: 2026-10-05
-- AUTORLUS: ChatGPT abil koostatud tervikpaketi uus kontroll.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Fail: 01_loppkontroll.sql | Etapp 07 | 05.10.2026.
-- Uus tervikpaketi kontroll: ChatGPT abil koostatud, algautorite tööd ei asenda.
-- Sisend: etappide 01–05 tabelid; etapp 06 on valikuline analüüs.
-- Ainult lugemine. Iga kohustusliku vea korral katkestab RAISE EXCEPTION.
-- Ei kustuta ega muuda tabeleid. Käivita kogu fail ja logi tulemused.
DO $acceptance$
DECLARE
 r record;
 n bigint;
 differences bigint;
BEGIN
 FOR r IN SELECT unnest(ARRAY['vet_raw','vet_clean','vet_clean_mg_kg','vet_clean_bi']) AS table_name LOOP
  EXECUTE format('SELECT count(*) FROM vet_analytics.%I',r.table_name) INTO n;
  IF n <> 15202 THEN RAISE EXCEPTION '%: oodati 15202 toodet, saadi %',r.table_name,n; END IF;
 END LOOP;
 IF (SELECT count(*) FROM vet_powerbi.dim_products)<>15202
    OR (SELECT count(*) FROM vet_powerbi.dim_nutrients)<>49
    OR (SELECT count(*) FROM vet_powerbi.fact_product_nutrients)<>15202*49 THEN
  RAISE EXCEPTION 'Toodete/toitainete mudeli maht ei vasta kaasasolevale sisendile.';
 END IF;
 IF NOT EXISTS (SELECT 1 FROM vet_powerbi.fact_ingredients)
    OR NOT EXISTS (SELECT 1 FROM vet_analytics.product_ingredients_rows) THEN
  RAISE EXCEPTION 'Koostisosade eraldamine või kategoriseerimine pole lõpetatud.';
 END IF;
 IF to_regclass('vet_analytics.fact_ingredients') IS NOT NULL
    OR to_regclass('vet_powerbi.fact_product_ingredients') IS NOT NULL THEN
  RAISE EXCEPTION 'Leiti aegunud koostisosafakti objekt; kontrolli taastamise järjekorda.';
 END IF;
 IF EXISTS (SELECT 1 FROM vet_powerbi.fact_ingredients f
            LEFT JOIN vet_powerbi.dim_products p USING(product_id)
            LEFT JOIN vet_powerbi.dim_ingredients i USING(ingredient)
            WHERE p.product_id IS NULL OR i.ingredient IS NULL
               OR NULLIF(btrim(f.product_id),'') IS NULL
               OR NULLIF(btrim(f.ingredient),'') IS NULL
               OR NULLIF(btrim(f.category),'') IS NULL) THEN
  RAISE EXCEPTION 'Koostisosafaktis on puuduv võti, kategooria või dimensioonivaste.';
 END IF;
 IF EXISTS (SELECT 1 FROM vet_powerbi.fact_ingredients f
            WHERE NOT EXISTS (SELECT 1 FROM vet_analytics.product_ingredients_rows s
                              WHERE s._id::text=f.product_id AND s.ingredient=f.ingredient)) THEN
  RAISE EXCEPTION 'Koostisosafakt sisaldab eraldatud sisendis puuduvat paari.';
 END IF;
 IF EXISTS (SELECT 1 FROM vet_powerbi.fact_ingredients GROUP BY product_id,ingredient HAVING count(*)>1)
    OR EXISTS (SELECT 1 FROM vet_powerbi.dim_products GROUP BY lower(product_id) HAVING count(*)>1)
    OR EXISTS (SELECT 1 FROM vet_powerbi.dim_ingredients GROUP BY lower(ingredient) HAVING count(*)>1) THEN
  RAISE EXCEPTION 'Mudeli võtmetes või toote-koostisosa paarides on kordused.';
 END IF;
 IF EXISTS (SELECT 1 FROM vet_powerbi.fact_ingredients f
            JOIN vet_powerbi.dim_ingredients d USING(ingredient)
            WHERE d.category IS DISTINCT FROM f.category) THEN
  RAISE EXCEPTION 'Koostisosa kategooria dimensioonis erineb faktist; lahenda 05/003 kontrollnimekiri.';
 END IF;
 IF EXISTS (SELECT 1 FROM information_schema.columns
            WHERE table_schema='vet_powerbi' AND column_name ~* '[.][[:space:]]*(valu|unit)') THEN
  RAISE EXCEPTION 'BI tabelitesse on sattunud vanad väärtuse/ühiku päised.';
 END IF;
 -- Võrdleme iga näitaja väärtust kõigis kolmes järjestikuses väljundis.
 FOR r IN SELECT nutrient_id,nutrient_name FROM vet_powerbi.dim_nutrients LOOP
  EXECUTE format($q$
   SELECT count(*) FROM vet_analytics.vet_clean_mg_kg m
   LEFT JOIN vet_analytics.vet_clean_bi b USING(_id)
   LEFT JOIN vet_powerbi.fact_product_nutrients f
          ON f.product_id=m._id::text AND f.nutrient_id=%s
   WHERE b._id IS NULL OR f.product_id IS NULL
      OR m.%I IS DISTINCT FROM b.%I
      OR m.%I IS DISTINCT FROM f.value_mg_kg
  $q$,r.nutrient_id,r.nutrient_name,r.nutrient_name,r.nutrient_name) INTO differences;
  IF differences<>0 THEN RAISE EXCEPTION 'Näitaja % väärtustes % erinevust',r.nutrient_name,differences; END IF;
 END LOOP;
 IF vet_analytics.convert_to_mg_kg('0.6','ug') IS DISTINCT FROM 0.0006::numeric
    OR vet_analytics.convert_vitamin_to_mg_kg('1','IU','d3') IS DISTINCT FROM 0.000025::numeric THEN
  RAISE EXCEPTION 'Väikeste koguste täpsuskontroll ebaõnnestus.';
 END IF;
 RAISE NOTICE 'Põhitaastamine ja BI mudeli andmevastavus kontrollitud.';
END
$acceptance$;

-- Salvesta allolevad rea-arvud oma käivituslogisse.
SELECT 'vet_raw' AS object,count(*) AS rows FROM vet_analytics.vet_raw
UNION ALL SELECT 'vet_clean',count(*) FROM vet_analytics.vet_clean
UNION ALL SELECT 'vet_clean_mg_kg',count(*) FROM vet_analytics.vet_clean_mg_kg
UNION ALL SELECT 'vet_clean_bi',count(*) FROM vet_analytics.vet_clean_bi
UNION ALL SELECT 'product_ingredients_rows',count(*) FROM vet_analytics.product_ingredients_rows
UNION ALL SELECT 'ingredients_categories_reference',count(*) FROM vet_analytics.ingredients_categories_reference
UNION ALL SELECT 'dim_products',count(*) FROM vet_powerbi.dim_products
UNION ALL SELECT 'dim_nutrients',count(*) FROM vet_powerbi.dim_nutrients
UNION ALL SELECT 'dim_ingredients',count(*) FROM vet_powerbi.dim_ingredients
UNION ALL SELECT 'fact_product_nutrients',count(*) FROM vet_powerbi.fact_product_nutrients
UNION ALL SELECT 'fact_ingredients',count(*) FROM vet_powerbi.fact_ingredients;

-- Sobitamata read: info piirang, mitte nullvigade kontroll.
SELECT count(*) AS extracted_rows_without_category
FROM vet_analytics.product_ingredients_rows s
WHERE NOT EXISTS (SELECT 1 FROM vet_powerbi.fact_ingredients f
                  WHERE f.product_id=s._id::text AND f.ingredient=s.ingredient);
