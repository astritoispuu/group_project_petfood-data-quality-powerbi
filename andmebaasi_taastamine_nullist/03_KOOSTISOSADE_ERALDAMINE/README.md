# 03. Koostisosade eraldamine

Algse Pythoni koodi ja eraldamisreeglite autor on **Astrit**. Aktiivne kood kasutab tema uuemat versiooni, mis oli algpaketi `03_PRODUCT_INGREDIENTS_ROWS/EN` kaustas. Vanem eestikeelse kausta kood kasutas teistsuguseid eraldamisreegleid. Nüüd on mõlema keele jaoks üks ühine reeglistik. [English](README_EN.md).

## Sisend ja väljund

| Roll | Tabel | Veerud |
|---|---|---|
| Sisend | `vet_analytics.vet_clean_mg_kg` | `_id`, `product_name_fi`, `product_name_en`, `product_content` |
| Väljund | `vet_analytics.product_ingredients_rows` | `_id`, `product_name_fi`, `product_name_en`, `ingredient` |

Üks väljundrida tähendab üht eraldatud koostisosa ühe toote kohta. Koostisosade arv ei võrdu toodete arvuga. `_id` säilib selles vahetabelis; Liina järgnev etapp kasutab fakti väljundis `product_id` nime.

## Käivitamisjärjekord

1. Lõpeta etapid 01 ja 02. Käivita `003_preflight.sql`; tabel peab olemas olema ning ID-d peavad olema täidetud ja kordumatud.
2. Paigalda `requirements.txt` teegid ja täida skripti kõrval olev `.env` fail `.env.example` malli põhjal. Kasuta sama andmebaasi kui DBeaveris. Ühendusvajadused on `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`.
3. Käivita `product_extract.py`. Skript loeb PostgreSQL-i, mitte CSV-faili.
4. Kontrolli teadet `OUTPUT COMMITTED` ja tegelikku salvestatud ridade arvu. Käivita `004_validation.sql` ja kirjuta kokkuvõte käivituslogisse.
5. Jätka etappi 04. See eraldamise kood ei määra kategooriaid ega loo BI dimensioone.

PowerShelli käsud paketi juurkaustas:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r "03_KOOSTISOSADE_ERALDAMINE/requirements.txt"
Copy-Item "03_KOOSTISOSADE_ERALDAMINE/.env.example" "03_KOOSTISOSADE_ERALDAMINE/.env"
```

Need käsud loovad ühise Pythoni keskkonna ja ühendusseadete faili. Muuda `.env` väärtused enne järgmise käsu käivitamist enda andmeteks.

```powershell
.\.venv\Scripts\python.exe "03_KOOSTISOSADE_ERALDAMINE/product_extract.py" 2>&1 | Tee-Object "00_JUHEND_JA_LOGI/koostisosade_eraldamine_run.txt"
```

See käsk käivitab eraldamise ning salvestab terminaliväljundi logisse. Vigade korral peatu ja vaata lõpus olevat veateadet; logifaili olemasolu ei tõesta edukat salvestust.

## Eraldamisreeglid ja kirjutamine

Astriti loendid, puhastusfunktsioonid ja eraldamisreeglid on säilitatud. Tekst muudetakse väiketähtedeks, tuntud kirjavead parandatakse ning seadistatud eemaldusmustrid rakendatakse enne koostisosadeks jagamist. `PARENTHESES_MODE="join"` jätab sulgudes oleva teksti sama koostisosa juurde. `KEEP_E_NUMBERS=True` säilitab E-numbrid. Sama toote sees korduvad eraldatud koostisosad eemaldatakse; tühjad või üksnes sümbolitest koosnevad väärtused ei lähe väljundisse.

Python kirjutab 500-realiste partiidena staging-tabelisse `product_ingredients_rows_tmp`, asendab vana väljundtabeli ja nimetab staging-tabeli ümber ühe tehingu sees. Vea korral kirjutamine tühistatakse. Tühja tulemuse korral olemasolevat tabelit ei muudeta. Edukas asendamine loob uue tabeli; käsitsi lisatud tabeliindeksid, õigused ja piirangud ei kandu automaatselt üle. Sõltuvusi ei kustutata CASCADE-ga.

`EN/product_extract.py` on sama aktiivse koodi käivitusviide, mitte teine algoritm. `.env` paikneb alati selle kausta juures, kus on ühine `product_extract.py`.

## Tulemuse tõlgendamine

Kontrolli, et väljundi ID-d leiduvad allikas, puuduvad tühjad ID-d/koostisosad ja sama toote koostisosa ei kordu. Toodete puudumine eraldatud koostisosade tabelist võib tähendada puuduvaid kirjeldusi või eraldamise piiranguid. Testitud ridade arvud on [testiaruandes](../00_JUHEND_JA_LOGI/TESTIMISE_TULEMUSED.md).

Algpaketi ajaloolised CSV-eksportide arvud 83 012 ja 86 264 ei ole uue jooksu automaatne vastuvõtukriteerium. CSV-hetkekoopiad säilivad algses arhiivis. Käesolev põhijuhend taastab koostisosad koodiga algandmetest; käsitsi tehtud CSV-parandusi see ei taasesita.

## Astriti algsed juhendid

[README_koositsosade_eraldamine.md](README_koositsosade_eraldamine.md) ja [README_DBeaveri ja Pythoni ühendamine PostgreSQL.md](<README_DBeaveri ja Pythoni ühendamine PostgreSQL.md>) säilitavad Astriti sõnastuse ja ülesehituse. Nendes tehti ainult paketiga kooskõla jaoks vajalikud faktiparandused.