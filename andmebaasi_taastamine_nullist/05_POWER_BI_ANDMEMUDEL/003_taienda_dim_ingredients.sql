-- PAKETT: andmebaasi_taastamine_nullist | ETAPP: 05_POWER_BI_ANDMEMUDEL | VERSIOON: 2026-10-05
-- AUTORLUS: Nimeline algautor pole allikas märgitud.
-- JUHEND: mooduli README.md; tervikjärjekord kaustas 00_JUHEND_JA_LOGI.
-- LOGI: 00_JUHEND_JA_LOGI/KAIVITUSLOGI_MALL.csv. Käivita terve fail.

-- Käivita pärast tänast kategoriseerimine2.py koodi. Tabelite uuesti loomist pole vaja.
-- Käsitsi täidetud category jääb alles; faktist täidetakse ainult tühi väärtus.
-- Mitme kategooriaga koostisosa automaatselt ei valita: see tuleb allpool kontrollis välja.
DO $dimension$
BEGIN
 ALTER TABLE vet_powerbi.dim_ingredients ADD COLUMN IF NOT EXISTS category text;
 INSERT INTO vet_powerbi.dim_ingredients(ingredient)
 SELECT DISTINCT f.ingredient FROM vet_powerbi.fact_ingredients f
 WHERE NULLIF(trim(f.ingredient),'') IS NOT NULL
 AND NOT EXISTS (SELECT 1 FROM vet_powerbi.dim_ingredients d WHERE d.ingredient=f.ingredient);
 UPDATE vet_powerbi.dim_ingredients d SET category=f.category
 FROM (
 SELECT ingredient, min(category) AS category FROM vet_powerbi.fact_ingredients
 WHERE NULLIF(trim(category),'') IS NOT NULL
 GROUP BY ingredient HAVING count(DISTINCT category)=1
 ) f
 WHERE d.ingredient=f.ingredient AND NULLIF(trim(d.category),'') IS NULL;
END
$dimension$;
-- Vasturääkivad faktikategooriad: oodatav tühi tulemus; muidu lahenda käsitsi.
SELECT ingredient,string_agg(DISTINCT category,' | ') AS categories
FROM vet_powerbi.fact_ingredients WHERE NULLIF(trim(category),'') IS NOT NULL
GROUP BY ingredient HAVING count(DISTINCT category)>1;
-- Allesjäänud tühjad dimensioonikategooriad: kontrollnimekiri, mitte automaatne viga.
SELECT ingredient,category FROM vet_powerbi.dim_ingredients
WHERE NULLIF(trim(category),'') IS NULL;
-- Olemasoleva käsitsi kategooria erinevus faktist: kontrollnimekiri; ei kirjutata üle.
SELECT DISTINCT d.ingredient,d.category AS dimension_category,f.category AS fact_category
FROM vet_powerbi.dim_ingredients d JOIN vet_powerbi.fact_ingredients f USING(ingredient)
WHERE NULLIF(trim(d.category),'') IS NOT NULL AND d.category IS DISTINCT FROM f.category;
