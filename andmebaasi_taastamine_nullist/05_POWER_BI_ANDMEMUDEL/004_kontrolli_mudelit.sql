-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 05_POWER_BI_ANDMEMUDEL | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Ainult lugemiskontrollid. Salvesta kõik tulemused käivituslogisse.
SELECT 'dim_products' AS tabel,count(*) AS read FROM vet_powerbi.dim_products
UNION ALL SELECT 'dim_nutrients',count(*) FROM vet_powerbi.dim_nutrients
UNION ALL SELECT 'dim_ingredients',count(*) FROM vet_powerbi.dim_ingredients
UNION ALL SELECT 'fact_product_nutrients',count(*) FROM vet_powerbi.fact_product_nutrients
UNION ALL SELECT 'fact_ingredients',count(*) FROM vet_powerbi.fact_ingredients;
-- Toitainete fakti rea-arv peab olema toodete arv × toitainete arv.
SELECT (SELECT count(*) FROM vet_powerbi.fact_product_nutrients) AS actual,
       (SELECT count(*) FROM vet_powerbi.dim_products)*(SELECT count(*) FROM vet_powerbi.dim_nutrients) AS expected;
-- Koostisosade lõppasukoht: vana asukoht NULL; siht olemas.
SELECT to_regclass('vet_analytics.fact_ingredients') AS vana_asukoht,
       to_regclass('vet_powerbi.fact_ingredients') AS uus_asukoht;
-- Keelatud päised: oodatav tühi tulemus.
SELECT table_name,column_name FROM information_schema.columns
WHERE table_schema='vet_powerbi' AND column_name ~* '[.][[:space:]]*(valu|unit)';
-- Võtme- ja vastavuskontrollid: oodatav kõik 0.
SELECT 'ingredient_products_missing' AS kontroll,count(*) AS vead
FROM vet_powerbi.fact_ingredients f LEFT JOIN vet_powerbi.dim_products d USING(product_id) WHERE d.product_id IS NULL
UNION ALL SELECT 'ingredients_missing_in_dimension',count(*)
FROM vet_powerbi.fact_ingredients f LEFT JOIN vet_powerbi.dim_ingredients d USING(ingredient) WHERE d.ingredient IS NULL
UNION ALL SELECT 'empty_ingredient_product_id',count(*)
FROM vet_powerbi.fact_ingredients WHERE NULLIF(trim(product_id),'') IS NULL
UNION ALL SELECT 'duplicate_product_key',count(*) FROM
(SELECT lower(product_id) FROM vet_powerbi.dim_products GROUP BY 1 HAVING count(*)>1) x
UNION ALL SELECT 'duplicate_ingredient_key',count(*) FROM
(SELECT lower(ingredient) FROM vet_powerbi.dim_ingredients GROUP BY 1 HAVING count(*)>1) x;
-- Mitme identse sisendrida korral säilitab Python need; näitab kordusi, ei eemalda neid.
SELECT product_id,ingredient,category,count(*) FROM vet_powerbi.fact_ingredients
GROUP BY 1,2,3 HAVING count(*)>1;
-- Täielik toitaineväärtuste võrdlus lähteveeruga, sh NULL/0 ja täpsus.
DO $verify$
DECLARE r record; differences bigint;
BEGIN
 FOR r IN SELECT nutrient_id,nutrient_name FROM vet_powerbi.dim_nutrients LOOP
  EXECUTE format($q$
  SELECT count(*) FROM vet_analytics.vet_clean_bi s
  LEFT JOIN vet_powerbi.fact_product_nutrients f
  ON f.product_id=s._id::text AND f.nutrient_id=%s
  WHERE f.product_id IS NULL OR f.value_mg_kg IS DISTINCT FROM NULLIF(trim(s.%I::text),'')::numeric
  $q$,r.nutrient_id,r.nutrient_name) INTO differences;
  IF differences<>0 THEN RAISE EXCEPTION 'Toitaine % erinevusi %',r.nutrient_name,differences; END IF;
 END LOOP;
 RAISE NOTICE 'Kõik registreeritud toitainete väärtused vastavad vet_clean_bi allikale.';
END
$verify$;
