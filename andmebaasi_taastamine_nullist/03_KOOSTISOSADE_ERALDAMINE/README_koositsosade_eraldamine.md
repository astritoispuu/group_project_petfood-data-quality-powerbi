
# Andmetöötlus Pythoniga

## Eesmärk ja tulemus

Toodete koostisandmed olid andmebaasis vabateksti kujul. Andmed on struktureeritud Pythoni skriptiga, mis loeb andmed PostgreSQL-i tabelist `vet_analytics.vet_clean_mg_kg`, puhastab koostisteksti reeglipõhiselt (regulaaravaldised turundusfraaside, ühikute, toitainenäitajate ja liiga üldiste kategooriate eemaldamiseks), tükeldab teksti eraldajate alusel üksikuteks koostisosadeks ning eemaldab iga toote piires duplikaadid.

Tulemus salvestatakse pika formaadi tabelisse `vet_analytics.product_ingredients_rows`, kus iga rida vastab ühele toote ja koostisosa paarile. Tabelis on veerud `_id`, `product_name_fi`, `product_name_en` ja `ingredient`.

<img width="369" height="176" alt="image001" src="https://github.com/user-attachments/assets/7e5c12cd-62d3-48b4-9a47-dfcbd00c81a2" />

**Näide:** sisend „Chicken (40%), rice, fish oil, vitamins" annab kolm rida: `chicken`, `rice`, `fish oil`. Protsent ja üldine „vitamins" jäävad välja.

Puhastusreegleid on täpsustatud iteratiivselt: sama tsüklit on korratud ja tulemust parandatud iga ringiga. Tulemust on kontrollitud visuaalselt.

## Andmetöötluse sammud

Skript teeb järgmist:

1. Loeb andmed PostgreSQL-i andmebaasist.
2. Puhastab koostisteksti reeglipõhiselt.
3. Tükeldab teksti üksikuteks koostisosadeks, kus iga toote unikaalne koostisosa on viidud omaette reale koos vastava toote ID-ga (`_id`).
4. Eemaldab iga toote piires duplikaadid.
5. Salvestab tulemuse pika formaadi tabelisse.
6. Trükib konsooli kokkuvõtte töötluse tulemustest.

### 1. Teksti normaliseerimine

- Kõik reavahetused (`\r\n`, `\r`, `\n`) asendatakse kohe alguses komadega, et tekstiosad ei „rebeneks" pooleks.
- Tekst viiakse väiketähtedeks.
- Rakendatakse `TEXT_REPLACEMENTS`: asendused, mis ühtlustavad kirjapilti ja parandavad kodeeringuvead (nt `â’`, `ã¤` on valesti dekodeeritud UTF-8). Näiteks `luomukana` (mahekana) → `kana`.

### 2. Kaitstud mustrid

Enne tükeldamist kaitstakse terminid `omega-3` (ka `omega 3`, `omega3`) ja E-numbrid (nt `e322`), et sidekriips ja number neid pooleks ei lõikaks. Pärast tükeldamist need taastatakse.

### 3. Fraaside eemaldamine (`REMOVE_PHRASES`)

Pikad fraasid, mis eemaldatakse enne tükeldamist. Näiteks:

- turundusväljendid („a pinch of love", „freshly prepared", „quality ingredients");
- analüüsi- ja koostisetekstide pealkirjad („analyyttiset aineosat" = analüütilised koostisosad);
- liiga üldised soome keele kategooriad („kasviperäiset tuotteet" = taimsed tooted, „sivutuotteet" = kõrvalsaadused, „mineraalit", „rasvat").

Kõik fraasid liidetakse üheks mustriks `PHRASE_PATTERN`, kus `|` tähendab „või". `re.IGNORECASE` muudab otsingu tõstutundetuks ja `\b` tähistab sõnapiiri, nii et näiteks `\bvilja\b` ei eemalda sõna keskelt. Pikemad fraasid asetatakse enne lühemaid, sest regulaaravaldis valib esimese sobiva variandi.

### 4. Sulgudes olev tekst

Sulgudes olev tekst liidetakse samasse koostisosasse (`rasv (kana)` → `rasv kana`). Käitumist saab muuta seadega `PARENTHESES_MODE`:

- `join` (vaikimisi): sulud eemaldatakse, sisu jääb samasse koostisosasse;
- `extract`: sulgudes olev tekst muutub eraldi koostisosaks (`rasv` ja `kana`);
- `remove`: sulgudes olev tekst kustutatakse.

### 5. Tükeldamine

Tekst tükeldatakse koostisosadeks, kasutades eraldajatena:

- kirjavahemärke (`,`, `.`, `:`, `;`, `+`, `&`, `%`, `-`);
- numbreid (`\d+`);
- tekstilisi sidesõnu (`with`, `and`, `ja`).

### 6. Iga koostisosa puhastamine

- **Üksikute sõnade eemaldamine (`REMOVE_WORDS`).** Sõnad ja lühikesed väljendid, mis jäävad koostisosa kõrvale (`organic`, `fresh`, `dried`, `raw`, `norwegian`, `mg`, `kg`). Need eemaldatakse tervete sõnadena (`WORD_PATTERN`). `re.escape` kaitseb erimärkide (nt `%`, `/`) eest.
- **Välistatavad sõnad (`EXCLUDE_KEYWORDS`).** Sõnad, mis ei ole koostisosad, vaid analüütilised näitajad (tuhk, niiskus, energia, vitamiinid, mineraalid, aminohapped) või ühikud (`kcal`, `iu`). Kui koostisosa on täpselt selline sõna või algab/lõpeb sellega, jäetakse see välja.
- **Kirjeldavad sõnad.** Välja jäetakse koostisosad, mis sisaldavad kirjeldavaid sõnu (`source`, `support`, `lähde`, `vitamin`).
- **Üldised filtrid.** Välja jäetakse koostisosad, mis sisaldavad numbreid, on lühemad kui 2 märki või koosnevad rohkem kui 4 sõnast.

### 7. Duplikaatide eemaldamine

Duplikaadid eemaldatakse iga toote piires eraldi (sama koostisosa jääb teiste toodete andmetesse alles). Kontroll toimub viimase sammuna, pärast kõiki puhastusi, hulga `seen` abil. Alles jäetakse esimesena ettejuhtuv koostisosa, nii et retsepti algne järjekord säilib. Loendurid `STATS["raw_splits"]` ja `STATS["removed_duplicates"]` koguvad kokkuvõtte jaoks statistikat.

### 8. Sorteerimine ja salvestamine

- **Käivitamine.** Skript käib tsükliga läbi kõik tooted ja ehitab tulemusest tabeli `df_long`.
- **Sorteerimine.** Veerud seatakse kindlasse järjekorda ja read sorteeritakse `_id` järgi (`kind="stable"` säilitab koostisosade algse järjekorra tootes).
- **Salvestamine.** Tulemus kirjutatakse PostgreSQL-i 500 rea kaupa kõigepealt ajutisse tabelisse `product_ingredients_rows_tmp`. Kui kõik read on edukalt kirjutatud, kustutatakse vana väljundtabel ja ajutine tabel nimetatakse ümber. Kogu protsess toimub ühe tehingu sees: vea korral tehakse rollback ja vana tabel jääb muutmata.
- **Kokkuvõte.** Konsoolis trükitakse toodete arv, tükeldatud koostisosade arv, eemaldatud duplikaadid ja lõplik ridade arv. Seejärel suletakse ühendus.

## Kuidas väljundit lugeda?

Pärast töö lõppu prindib skript konsooli kokkuvõtte:

```text
============================================================
TÖÖTLUS VALMIS
============================================================
Algne ridade arv (tooted): 15202
Tükeldatud koostisosade arv: 93622
Eemaldatud duplikaate: 7358
Lõplik ridade arv: 86264
Väljundtabel: vet_analytics.product_ingredients_rows
Sulgude režiim: join
============================================================
```

- **Algne ridade arv (tooted):** sisendtabeli toodete arv.
- **Tükeldatud koostisosade arv:** koostisosade arv pärast puhastust, kuid enne duplikaatide eemaldamist.
- **Eemaldatud duplikaate:** korduvad koostisosad samas tootes.
- **Lõplik ridade arv:** väljundtabeli ridade arv (93 622 − 7 358 = 86 264).
- **Sulgude režiim:** kasutatud sulgude töötlemise seade (`join` tähendab, et sulgude sisu liideti samasse koostisosasse).

## Kasutusjuhend

### Eeldused

- Python 3.9 või uuem
- Teegid: `pip install pandas sqlalchemy psycopg2-binary python-dotenv`
- Ligipääs PostgreSQL-i andmebaasile ja olemasolev sisendtabel

### Sammud

1. Pane skript ja `.env` fail samasse kausta.
2. Loo `.env` fail:

```text
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=minu_andmebaas
   DB_USER=kasutaja
   DB_PASSWORD=parool
```

   > **Tähtis:** `.env` faili ei tohi GitHubi laadida. Lisa see `.gitignore` faili.

3. Kontrolli, et skeem `vet_analytics` ja sisendtabel on olemas. Vajadusel muuda `INPUT_TABLE` (praegu `vet_clean_mg_kg`).
4. Käivita: `python product_extract.py`.
5. Kontrolli tulemust ning eemalda sagedasemad ja kummalised mittekoostisosad:

```sql
   SELECT ingredient, COUNT(*) AS n
   FROM vet_analytics.product_ingredients_rows
   GROUP BY ingredient
   ORDER BY n DESC
   LIMIT 50;
```

   - Vaata tulemuse kõige sagedasemaid ja kummalisemaid koostisosi, näiteks koostisosa, mis ei ole koostisosa (`wet food`, `supports skin`), või sama asja kaks kirjapilti.
   - Lisa mittevajalikud `REMOVE_PHRASES`-i või `REMOVE_WORDS`-i.
   - Käivita skript uuesti ja vaata, kas probleem kadus ning kas tekkis uusi.

Koostisetekstid on vaba kujuga, nii et uued segavad fraasid ilmnevad alles tulemust vaadates. Seetõttu ei saa kõiki reegleid korraga valmis kirjutada, vaid tuleb neid tulemuse põhjal täiendada. Reeglid ei olnud algusest peale lõplikud, vaid täienesid mitme käivituse käigus.

> **Tähelepanu:** skript asendab tabeli `product_ingredients_rows` uue versiooniga. Vana tabel kustutatakse alles pärast edukat salvestust, kuid kui vana versioon on vaja alles jätta, tee enne varukoopia.

## Tulemuste ebatäpsused ja edasiarendus

### Tulemuste ebatäpsused

Koostisosade eraldamise tulemus ei ole täiesti puhas ning vajab valideerimist. Algandmed olid vabatekstina ja nende vormistus erines toodete ning tootjate lõikes: esines erinevaid keeli ja kirjapilte, turundusväljendeid ning kodeeringuvigu.

Puhastamiseks kasutati käsitsi koostatud reeglipõhist lähenemist. Reeglid sõltuvad kasutatud andmestikust ega pruugi teiste andmete puhul sama hästi toimida. Seetõttu võivad tulemusse jääda:

- **üksikud mittekoostisosad**, näiteks turundusfraasid;
- **vales kirjapildis koostisosad**;
- **ekslikult välja jäetud koostisosad**.

Lisaks ei ole soome-, rootis- ja ingliskeelseid vasteid (nt „kana" ja „chicken") ühtlustatud, mistõttu käsitletakse neid analüüsis eraldi.

### Edasiarendus

Tulemuse kvaliteeti on võimalik parandada mitmel viisil:

- **Reeglite täiendamine.** Eemaldatavate fraaside ja sõnade loendeid saab täiendada tulemuste edasise kontrolli põhjal.
- **Keelte ühtlustamine.** Soome-, rootsi- ja ingliskeelsed vasted saab ühtlustada tõlketabeli abil.
- **Masinõppe meetodid.** Koostisosade tuvastamiseks saab kasutada masinõppel põhinevaid lahendusi (nt nimetatud olemite tuvastamine), mis ei sõltu käsitsi koostatud reeglitest.
- **Kvaliteedi hindamine.** Soovitatav on hinnata tulemuse kvaliteeti juhuvalimi käsitsi kontrolliga.
