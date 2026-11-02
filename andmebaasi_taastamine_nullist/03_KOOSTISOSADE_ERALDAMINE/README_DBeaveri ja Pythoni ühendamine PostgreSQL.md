
**DBeaveri ja Pythoni ühendamine PostgreSQL-iga**

DBeaver ja Python ühendamine sama PostgreSQL-i andmebaasiga, et Python saaks andmeid DBeaver andmebaasist lugeda ja sinna tulemusi salvestada ning DBeaveris saaks neid andmeid vaadata ja kontrollida.

<img width="80%" alt="image001" src="https://github.com/user-attachments/assets/15fededa-5d6c-42b7-bfb4-23a1e21eacd2" />


Python ja DBeaver ei ühendu tavaliselt otse teineteisega. Mõlemad loovad eraldi ühenduse sama PostgreSQL-i serveriga.

**Enne jätkamist**

Kui **1\. Vajalikud programmid** on juba paigaldatud ja **2\. PostgreSQL-i ühendus DBeaveris** on loodud ning töötab, siis ei ole vaja neid samme uuesti teha.

➡ **Liigu edasi punktile 3. Valmista ette Pythoni projekt**

**1\. Vajalikud programmid**

Enne alustamist peavad arvutisse olema paigaldatud:

- **Python** – andmete töötlemiseks.
- **Visual Studio Code** – Pythoni koodi kirjutamiseks ja käivitamiseks.
- **DBeaver** – andmebaasi haldamiseks ja päringute tegemiseks.
- **PostgreSQL** – andmebaasiserver, kuhu andmed salvestatakse.

**2\. Kontrolli PostgreSQL-i ühenduse andmeid DBeaveris**

Kui DBeaveris on PostgreSQL-i ühendus juba loodud ja töötab, saad selle sammu vahele jätta.

1. Ava **DBeaver.**
2. Leia vasakpoolsest **Database Navigator** aknast oma PostgreSQL-i ühendus.
3. Tee ühendusel paremklõps ja vali **Edit Connection.**
4. Ava ühenduse seaded ning vaata üle järgmised andmed.

| **Main** |                                               |
| -------- | --------------------------------------------- |
| Host     | localhost                                     |
| Port     | 5432                                          |
| Database | postgres                                      |
| Username | postgres                                      |
| Password | \*\*\*\*\*\*\*\*\*\*\* /sinu salajane parool/ |

<img width="50%" alt="image004" src="https://github.com/user-attachments/assets/b154fdd3-260c-41d1-be2c-345d4239492f" />


Andmebaasi nimi ja kasutajanimi peavad olema samad, mida kasutad Pythonis. Parool peab olema õige, kuid seda ei ole vaja teistele avaldada.

**Märkus:** kõigil ei pea olema täpselt sama ühenduse nimi, kasutajanimi ega parool. Need võivad kasutajatel erineda. Oluline on, et Python ühenduks õige PostgreSQL-i serveri ja andmebaasiga.

**3\. Valmista ette Pythoni projekt**

1. Ava **Visual Studio Code**.
2. Vali **File → Open Folder** ja ava oma projekti kaust:

vali oma arvutis projekti kaust, kus asuvad Pythoni skriptid ja vajalikud lähteandmed.

1. Ava VS Code'is: **Terminal → New Terminal**

**4\. Paigalda vajalikud Pythoni teegid**

Sisesta VS Code'i terminali:

```
python -m pip install pandas sqlalchemy psycopg2-binary python-dotenv openpyxl
```

Need teegid võimaldavad Pythonil:

- pandas – andmeid töödelda;
- sqlalchemy – PostgreSQL-iga ühenduda;
- psycopg2-binary – PostgreSQL-i ühendust kasutada;
- python-dotenv – lugeda ühenduse andmeid .env failist;
- openpyxl – Exceli faile lugeda ja töödelda

**5\. Loo ühenduse jaoks .env fail**

Selleks, et andmebaasi parool ei oleks Pythoni koodis nähtaval, hoiame ühenduse andmeid eraldi failis.

1. Ava VS Code'is projekti kaust.
2. Loo uus fail nimega .env (faili nimi algab punktiga) kausta 03_KOOSTISOSADE_ERALDAMINE, product_extract.py kõrvale.
3. Lisa faili oma PostgreSQL-i ühenduse andmed:

DB_HOST=localhost

DB_PORT=5432

DB_NAME=sinu_andmebaasi_nimi

DB_USER=sinu_kasutajanimi

DB_PASSWORD="sinu_tegelik_parool"

Asenda näidisväärtused oma tegelike ühenduse andmetega, mis on DBeaveris.

Asenda sinu_parool oma PostgreSQL-i parooliga.

**Turvalisus:** .env fail sisaldab parooli. Ära jaga seda faili ega lisa seda GitHubi või muusse avalikku koodihoidlasse. Kui kasutate Git-i, lisa .env fail .gitignore faili.

**6\. Pythoni skripti käivitamine**

Skript asub taastamispaketis kaustas: 03_KOOSTISOSADE_ERALDAMINE

```
Projekt
│
├── 03_KOOSTISOSADE_ERALDAMINE
│   └── product_extract.py
```

-  **VS Code'i** vasakpoolses **Explorer**\-aknas leia projekti kaustast fail:

```
product_extract.py
```

Klõpsa failil, et see VS Code'is avada.

-   **VS Code'is vali:**

**Terminal → New Terminal**

Terminal avaneb VS Code'i alumises osas.

Terminali kaudu anna Pythonile käsk, et ta käivitaks faili: product_extract.py

Ava terminal kaustas 03_KOOSTISOSADE_ERALDAMINE ja kopeeri terminali: python product_extract.py


Vajuta: **Enter**

See käsk käivitab faili: product_extract.py

### 6.3 Lisainfo: mis toimub pärast käivitamist?

Pärast käsu käivitamist hakkab Python täitma product_extract.py skripti.

Skript:

1. loeb PostgreSQL-i ühenduse andmed .env failist;
2. loob ühenduse PostgreSQL-i andmebaasiga;
3. loeb lähteandmed PostgreSQL-i tabelist (vet_clean_mg_kg peab olema loodud selle taastamispaketi etapis 02):

```
vet_analytics.vet_clean_mg_kg
```

1. töötleb toodete koostisosade andmeid;
2. puhastab koostisosade teksti vastavalt skriptis määratud reeglitele;
3. eemaldab ebavajalikud väärtused ja kordused;
4. moodustab puhastatud koostisosadest eraldi read;
5. salvestab tulemused PostgreSQL-i tabelisse:

```
vet_analytics.product_ingredients_rows
```

<img width="40%" alt="image006" src="https://github.com/user-attachments/assets/6ee5cbf6-8365-4f97-8e82-c677139a12a7" />


### 6.4 Lisainfo: Kuidas aru saada, et skript töötab?

Terminalis hakkavad ilmuma skripti töö käigus teated.

Näiteks võib näha:

```
Salvestatud: 39000 / 76708 rida
Salvestatud: 76708 / 76708 rida
```

Täpsed ridade arvud võivad olla erinevad, sest need sõltuvad lähteandmetest ja koostisosade puhastamise reeglitest.

Oluline on, et skript lõpetaks töö **ilma veateateta**.

### 6.5 Värskenda DBeaveris andmebaasi

Kui Pythoni skript on lõpetanud töö, tuleb DBeaveris teha **Refresh**, et DBeaver loeks andmebaasi värske struktuuri uuesti sisse: vet_analytics.product_ingredients_rows

1. Mine **DBeaverisse**.
2. Vasakule **Database Navigator** aknasse.
3. Leia oma PostgreSQL-i ühendus.
4. Ava ühendus, kui see ei ole juba avatud.
5. Leia skeem: vet_analytics
6. Tee skeemil **paremklõps**.
7. Vali: **Refresh**

Pärast seda värskendab DBeaver andmebaasi struktuuri. Nimekirja ilmub: product_ingredients_rows


#### Kui tabelit ikka ei näe

```
vet_analytics
   ↓
Tables
```

Tee kaustal **Tables** paremklõps → **Refresh**.

Pärast värskendamist peaks nimekirja ilmuma: product_ingredients_rows

### 7\. Kontrolli tulemust DBeaveris

Kui Python on töö lõpetanud, ava **DBeaver**.

Ava **SQL Editor** ja sisesta:

```
SELECT COUNT(*) AS ridade_arv
FROM vet_analytics.product_ingredients_rows;
```

Käivita päring.

See näitab, mitu rida Python väljundtabelisse salvestas.
