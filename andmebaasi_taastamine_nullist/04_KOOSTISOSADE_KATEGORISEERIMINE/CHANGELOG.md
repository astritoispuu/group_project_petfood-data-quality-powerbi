# Muudatuste logi

Kuupäev: **05.10.2026**. Algse kategoriseerimise ja fact_ingredients loomise koodi koostas Liina; nende põhiloogika säilitati. Muudatuste ettevalmistamine ei tähenda andmebaasis käivitamist.

| ID | Etapp | Muudatus ja põhjus |
|---|---|---|
| CAT_REV_01 | CAT_STEP_01 | SQL siht `vet_analytics.fact_ingredients` → `vet_powerbi.fact_ingredients`; `_id` → `product_id`, et ühtida praeguse BI faktiga. |
| CAT_REV_02 | CAT_STEP_02 | Väljundi sõnastikus ja andmeraami veeruloendis `_id` → `product_id`. Sisend `_id` jäi muutmata; kirjutamise siht oli juba algfailis `vet_powerbi`. |
| CAT_REV_03 | CAT_STEP_00 | Lisati puuduva võrdlustabeli DDL kõigi seitsme CSV päisega. Olemasolevale tabelile lisatakse kaks puuduvat auditivälja. |
| CAT_REV_04 | CAT_STEP_01 / 02 | Puuduv skeem luuakse; olemasolevat tabelit hoitakse alles. SQL/Python kontrollivad nõutud veerge ja Python kontrollib nõutud tabeleid enne kirjutamist. |
| CAT_REV_05 | CAT_STEP_02 | Säilitati DATABASE_URL tugi ja lisati varasema eraldusskriptiga ühtiv DB_* kuju; URL.create käsitleb parooli erimärke. |
| CAT_REV_06 | CAT_STEP_02 | Tühja tulemuse kaitse lisati enne TRUNCATE käsku. OUTPUT COMMITTED väljastatakse alles pärast tehingu edukat lõppu. |
| CAT_REV_07 | CAT_STEP_03 | Lisati mahu, kohustuslike väärtuste, lähtepaaride, duplikaatide ja kategooriate SQL-kontroll. |
| CAT_REV_08 | Kõik | Ühtlustati päised ja etapitähised; lisati teegid, ühenduse mall, gitignore, README ja eraldi käivituslogi. |
| CAT_REV_09 | Kõik | Samad aktiivsed failid eesti ja inglise kaustas. CSV ja andmebaasiobjektide nimed säilitati. Algfailid kopeeriti muutmata originals kausta. |
| CAT_REV_10 | Kõik | Kasutaja täpsustuse põhjal lisati algse koodi autorina Liina README-sse ja algsete skriptide päistesse. Hiljem lisatud abiskriptid märgiti täiendustena. Käivitatavat koodi ei muudetud. |

## Säilitatud käitumine

Täpsed puhastatud tekstivasted, esimene + kategooria, kategooriata/vasteta sisendite väljajätmine, protein/oil/carbs väärtused ja ühe väljundrea loomine iga sobitatud sisendrea kohta jäid samaks. Human Review ei saanud uut filtreerimisreeglit. Dimensiooni ega toitainete tabeleid ei muudetud.

## Kohalik kontroll

- CSV: 6759 rida, seitse päist, 2193 kategooriata rida, 690 + kategooriaga rida, 18 korduvat puhastatud võtit. Kasutatavate duplikaatide vahel vastete konflikte ei leitud.
- Mõlema keele CSV ja kõik originals failid võrreldi algfailidega bait-baidilt.
- Pythoni mõlemad versioonid läbivad süntaksikontrolli.
- Testasendustega kontrolliti mõlemas keeles: edukat sobitamist, tühja sisendit, kasutatavate kategooriateta võrdlustabelit, puuduvat tabelit, puuduvat product_id veergu, kirjutusviga ja DB_* ühenduskuju. Lisaks võrreldi täismahus CSV-fixtuuri sobitamist algse koodiga; kategoorialoogika tulemused kattuvad.
- Need kontrollid ei käivita SQL-i ega päris PostgreSQL-i tehinguid. PostgreSQL-i tööriistu ja ühendust polnud saadaval. SQL vaadati staatiliselt üle; tegelik andmebaasikäivitus on NOT_RUN.

Kontrollitulemus: **24 kontrolli läbitud**. Täis-CSV testis oli 6759 sisendrida ja 4566 väljundrida; see fixture kasutab võrdlustabeli Ingredient veergu sisendina, mitte tegelikku product_ingredients_rows tabelit. Mõlema keele tulemus kattus algkoodi tulemusega pärast väljundi võtme ümbernimetamist.
