# Koostisosade kategoriseerimine ja fact_ingredients loomine

**Algse kategoriseerimise koodi ja fact_ingredients tabeli loomise koodi koostas Liina.** Selles versioonis ühtlustati tabeliviited ja dokumentatsioon ning lisati taastamise ja kontrolli abiskriptid.

## 1. Eesmärk ja koht taastamises

See moodul kuulub kausta `andmebaasi_taastamine_nullist/04_KOOSTISOSADE_KATEGORISEERIMINE`. Python loeb varem eraldatud koostisosad ja võrdlustabeli otse PostgreSQL-ist, leiab täpsed tekstivasted ning täidab BI fakti. Skript ei loe CSV-d otse; CSV imporditakse kõigepealt andmebaasi.

Enne alustamist peab eelmine koostisosade eraldamise või CSV-taastamise etapp olema loonud `vet_analytics.product_ingredients_rows`. Toitainete normaliseerimist ja `vet_clean_bi` loomist juhendab eraldi moodul. Kategoriseerimine ei loe `vet_clean_bi` tabelit.

| Roll | Tabel | Nõutud veerud |
|---|---|---|
| Sisend | `vet_analytics.product_ingredients_rows` | `_id`, `ingredient`; teised veerud võivad alles jääda |
| Võrdlustabel | `vet_analytics.ingredients_categories_reference` | Kõik seitse CSV päist |
| BI väljund | `vet_powerbi.fact_ingredients` | `product_id`, `ingredient`, `category`, `protein`, `oil`, `carbs` |

Sisendtabelis säilib `_id`; Python kasutab selle väärtust väljundi `product_id` veerus. `vet_analytics.fact_ingredients` tabelit enam ei looda. Skript ei liiguta ega kustuta ajaloolisi tabeleid.

## 2. Failid ja käivitusjärjekord

| Etapp | Fail / tegevus | Tulemus |
|---|---|---|
| `CAT_STEP_00` | `00_create_reference_table.sql`, seejärel CSV import | Seitsmeveeruline võrdlustabel koos andmetega |
| `CAT_STEP_01` | `fact_ingredients_loomine.sql` | Kuueveeruline fakt tabelis `vet_powerbi` |
| `CAT_STEP_02` | `kategoriseerimine2.py` | Kategoriseeritud faktiridade salvestamine |
| `CAT_STEP_03` | `03_validation.sql` | Mahu, võtmete, duplikaatide ja kategooriate kontroll |

Lisafailid: `categories_reference.csv`, `requirements.txt`, `.env.example`, `.gitignore`, `CHANGELOG.md` ning `EXECUTION_LOG.md`. Eesti ja inglise kaustad on alternatiivsed, samaväärsed paketid: käivita ainult ühe keele versiooni. `../99_ARHIIV_EI_KAIVITA/algne_pakett_20261005.zip` säilitab neli algfaili võrdluseks; need ei kuulu käivitusjärjekorda.

## 3. Võrdlustabeli taastamine DBeaveris

1. Ühendu andmebaasiga, kus asub `vet_analytics.product_ingredients_rows`.
2. Käivita täielik `00_create_reference_table.sql`. See loob puuduva skeemi ja tabeli. Varem ainult viie veeruga loodud tabelile lisab see `Human Review` ja `Review Reason` väljad.
3. Vali võrdlustabel → **Import Data** → CSV ning vali selle kausta `categories_reference.csv`.
4. Kasuta UTF-8 kodeeringut, eraldajat **`;`**, esimest rida päistena ja tekstipiirajat `"`. Väärtused kaardista veerunimede järgi täpselt; tühjad väljad võivad muutuda NULL-iks.
5. Kontrolli kõiki seitset päist: `Ingredient`, `Category`, `Human Review`, `Review Reason`, `Protein`, `Oil`, `Carbs`. Kõik veerud on TEXT.
6. Esmakordsel taastamisel impordi tühja tabelisse. Kordusimpordil ära lisa samu ridu olemasolevale sisule. Kui asendad selle CSV-ga kogu võrdlustabeli, kasuta DBeaveri impordi sihttabeli tühjendamise valikut pärast olemasoleva sisu varundamist. Käsitsi tehtud täiendused ei kuulu kaasasolevasse CSV-sse.

Kaasasolevas CSV-s on **6759 rida**, millest **2193** on kategooriata ja **690** sisaldab kategoorias `+` märki. Puhastatud koostisosavõtmetest kordub **18**; kasutatavate vastete kategooria/protein/oil/carbs väärtustes nende vahel konflikte ei leitud. Imporditud hetkekoopia korral peaks tabelis olema 6759 rida. Hilisemate täienduste korral logi tegelik maht.

CSV on mõlemas keelekaustas bait-baidilt sama. Andmeväärtusi ja päiseid ei tõlgita, sest need on sobitamise sisend ja andmebaasileping.

## 4. Fakti loomine

Käivita DBeaveris täielik `fact_ingredients_loomine.sql`. See loob `vet_powerbi` skeemi ja tühja kuueveerulise fakti ainult siis, kui neid pole. Olemasolevaid faktiridu ei kustutata. Kontrollplokk nõuab olemasolevalt tabelilt kõiki kuut veergu.

Kui vana tabel kasutab endiselt `_id` veergu, katkeb kontroll. Järgi sel juhul projekti juba tehtud veeru ümbernimetamise sammu ja kontrolli BI sõltuvusi; see skript ei tee varjatud migratsiooni. Praegune eeldus on `product_id`.

Toote ID ei ole siin unikaalne: samal tootel võib olla mitu koostisosa. Skript ei lisa uut primaarvõtit ega muuda olemasolevaid BI võtmeid, indekseid või õigusi.

## 5. Pythoni ühendus ja teegid

Kasuta VS Code'is sama PostgreSQL-i serverit ja andmebaasi nagu DBeaveris. Järgmised PowerShelli käsud loovad keskkonna ja paigaldavad teegid; sobiva olemasoleva keskkonna korral kasuta seda.

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Need käsud käivita valitud keelekaustas. `pandas` töötleb tabeleid, `SQLAlchemy` haldab ühendust, `psycopg2-binary` on PostgreSQL-i draiver ja `python-dotenv` loeb seadeid. CSV/Exceli lugemiseks lisateeke ei vajata. Logi edukalt kasutatud teegiversioonid.

Kopeeri `.env.example` skripti kõrvale nimega `.env` ja asenda kohatäide oma parooliga:

```dotenv
DB_HOST=localhost
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD="sinu_tegelik_parool"
```

See kuju ühtib koostisosade eraldamise mooduliga. `URL.create()` käsitleb parooli erimärke. Säilib ka varasema `DATABASE_URL` kuju tugi. Kui see muutuja on määratud, kasutatakse seda DB_* seadete asemel. Juba määratud keskkonnamuutujad on `.env` väärtustest eelistatumad. `DATABASE_URL` puhul peab draiver vastama paigaldatud teegile; selle paketi draiver on `postgresql+psycopg2`. URL-is tuleb parooli erimärgid URL-kodeerida.

`.env` ei kuulu GitHubi ega jagatavasse paketti. Lisatud `.gitignore` välistab selle. Kõik kasutatavad teegid tuleb paigaldada sellesse Pythoni keskkonda, millega skripti käivitad.

## 6. Kategoriseerimise käivitamine

1. Veendu, et võrdlustabel on imporditud ja `CAT_STEP_01` on tehtud.
2. Käivita skript alloleva käsuga. Muuda korduskäivituse korral logifaili lõpunumbrit, et varasem tulemus säiliks.
3. Kontrolli väljundis `OUTPUT COMMITTED` teadet. Ainult sobitamise kokkuvõte ei tõenda salvestamist.
4. Värskenda DBeaveris tabeleid, käivita `03_validation.sql` ja täida `EXECUTION_LOG.md`.

```powershell
.\.venv\Scripts\python.exe kategoriseerimine2.py 2>&1 | Tee-Object CAT_STEP_02_run_20261005_01.txt
```

Python kontrollib enne lugemist kolme tabeli ja nõutud veergude olemasolu. Kui kasutatavaid väljundridu ei teki, katkeb see enne sihttabeli tühjendamist.

Edukas käivitus **asendab kogu `vet_powerbi.fact_ingredients` sisu**. `TRUNCATE` ja `append` toimuvad ühes `engine.begin()` tehingus. Kirjutusvea korral pööratakse muudatused tagasi. Tabelit ei looda uuesti, seega säilivad selle olemasolevad indeksid ja õigused. Võõrvõtmed, kohustuslikud lisaveerud, puuduvad õigused või sobimatud tüübid võivad kirjutamise peatada; skript ei kasuta CASCADE. Ära käivita paralleelselt sama fakti uuendusi.

## 7. Säilitatud sobitusreeglid

- Sobitamiseks eemaldatakse nähtamatud/juhtmärgid, kasutatakse väiketähti ning ühtlustatakse tühikud. Algne `ingredient` tekst jääb väljundisse.
- Sobitus on täpne puhastatud tekstivaste; osalisi vasteid, uusi tõlkeid ega oletuslikke kategooriaid ei lisata.
- Tühi koostisosa ning vaste või kategooriata sisendrida jääb faktist välja. `Not found in reference` loendur hõlmab ka võrdlustabelis esinevaid, kuid puuduva kategooriaga koostisosi, sest neid sobitussõnastikku ei lisata.
- `+` märgiga kategooriatest valitakse esimene. Näiteks `animal protein + oil` muutub `animal protein` väärtuseks.
- `protein`, `oil` ja `carbs` kopeeritakse võrdlustabelist. `Yes`, `No` ja `Review` väärtusi ei teisendata jah/ei lippudeks.
- `Human Review` ja `Review Reason` säilivad võrdlustabelis, kuid ei lähe kuueveerulisse fakti ega mõjuta senist sobitamist. Seetõttu võib käsitsi kontrolli vajav rida saada faktis kategooria.
- Üks sobitatud sisendrida annab ühe väljundrea. Kood ei eemalda sisendduplikaate. Korduva puhastatud võrdlusvõtme korral on lubatud ainult samaväärsed kasutatavad vasted; vastuoluline category/protein/oil/carbs peatab koodi enne fakti kirjutamist. Lisatud CSV-s kasutatavate duplikaatide väärtused ei erine. Hilisemaid vastuolusid tuleb enne käivitamist lahendada.

Sobitamata või väljundist välja jäetud koostisosa ei tõenda koostisosa puudumist toidus. See piirang on oluline allergeenifiltrite tulemuste tõlgendamisel.

## 8. BI sõltuvused ja kontroll

Pärast edukat kategoriseerimist uuenda projekti olemasoleva juhendi järgi `vet_powerbi.dim_ingredients`, kaasa arvatud selle `category` väärtused, ja värskenda Power BI andmeid. See moodul dimensiooni ei muuda, sest selle täielikku loomisskripti ega käsitsi sisestatud väärtusi pole nende nelja faili hulgas.

Taastamisel tee fakti kategoriseerimine enne sellest sõltuva dimensiooni lõplikku täitmist. Hilisem skeemi nullist taastamise skript võib fakti kustutada: sellisel juhul loo ja täida fakt uuesti. Toote seos kasutab fakti `product_id` veergu ning projekti olemasolevat tootedimensiooni.

Kontrollpäringute vealoendurid ja tundmatute toote–koostisosa paaride tulemus peavad olema null. Duplikaadid tuleb üle vaadata; koostisosaridade arv ei pea võrduma toodete ega sisendridade arvuga. Võrdle konsooli väljundmahtu tabelisse salvestatud mahuga.

## 9. Logimine ja kontrolli ulatus

PostgreSQL-i ühendust ega päris tabelitesse kirjutamist siin ei tehtud. Kõik andmebaasietapid on **NOT_RUN**. 
