# Vet: algandmete import ja kinnitatud puhastus

See juhend kirjeldab kuue põhifailiga etappi: algne CSV → `vet_raw` → parandatud `vet_clean`. Failinimed on jäetud samaks nagu saadetud komplektis; järjekorra määrab allolev tabel.

## Mida see etapp loob?

| Objekt | Roll | Seis etapi lõpus |
|---|---|---|
| `vet_analytics` | Projekti skeem | Olemas |
| `vet_analytics.vet_raw` | Imporditud algandmed, mille alusel parandusi võrrelda | 15 202 rida, 215 TEXT veergu; puhastusskriptid seda ei muuda |
| `vet_analytics.vet_clean` | Eraldi töökoopia | Sama toodete ja veergude hulk; kinnitatud kirjavead ning Mn/Fe/I nihked parandatud |
| `vet_clean_id_uq` | Unikaalne indeks `vet_clean._id` veerul | Takistab sama ID kordumist töökoopias |

`vet_clean` toitainete väärtused jäävad selles etapis tekstiks ning `.value` ja `.unit` veerud jäävad alles. mg/kg teisendused, `vet_clean_bi`, koostisosade kategoriseerimine ja `vet_powerbi` mudel kuuluvad järgnevatesse etappidesse. See ZIP ei ole kogu tänase andmebaasi varukoopia.

## Millal seda järjekorda kasutada?

Kasuta seda **algsest puhastamata CSV-st alustamisel**. Kui taastad juba puhastatud `vet_clean` CSV või värske täieliku varukoopia, kasuta selle taastamisviisi juhendit. Neid kolme algusviisi ei käivitata üksteise järel.

Vaja on PostgreSQL-i serverit ja DBeaverit. Kõik kuus faili ava sama sihtandmebaasi ühenduses. Kasuta uut tühja sihtbaasi või baasi, kus projekti `vet_analytics` skeemi veel ei ole. Skeemi loomiskood ei asenda olemasolevaid objekte.

SQL-failid on UTF-8. Käivita DBeaveris **kogu skript**, tavaliselt Alt+X / Execute SQL Script. Ära käivita ainult kursorialust lauset. Vaata iga etapi tulemused üle. Vea korral peatu; kui tehing jäi avatuks, tee `ROLLBACK` ning kõrvalda vea põhjus. Järgmise etapiga jätkatakse alles siis, kui käesolev etapp lõppes veata ja kontrollid vastavad juhendile.

## Algfail

Kaasas on `data/vetsy_nutrition_readkorras (1) - Copy.csv`: 15 202 andmerida ning 215 veergu. Tegemist on algse puhastamata sisendiga. Ära vali selle asemele `vet_clean_2026-09-28.csv` faili.

Algse CSV SHA-256 kontrollsumma: `c02e92e88d05df091f9e1f5e7b11aaca74d99a3de3c0bd60b55604383badd8d5`.

## Täpne käivitusjärjekord

SQL-failid asuvad `sql` kaustas. Käsitsi import toimub esimese ja teise SQL-faili vahel.

| Etapp | Fail või tegevus | Eesmärk | Millal jätkata? |
|---|---|---|---|
| 01 | `001.01_skeemi_tabeli_loomine.sql` | Loob skeemi ja tühja `vet_raw` tabeli | Skript lõppes veata; tabel on olemas |
| Import | Impordi algne CSV tabelisse `vet_analytics.vet_raw` | Täidab algtabeli | Import lõppes veata; järgmine fail kinnitab mahu ja võtmed |
| 02 | `001.03_impordi_kontroll.sql` | Kontrollib ridu, ID-sid, veerge ja tüüpe | 15 202 rida, 15 202 eri ID-d, 0 puuduvaid/korduvaid ID-sid, 215 TEXT veergu |
| 03 | `001.04_vet_clean_tookoopia.sql` | Loob täpse töökoopia ja unikaalse indeksi | Koopia kontroll läbis; mõlemal tabelil 15 202 rida |
| 04 | `002.09_topeltpunktide_leidmine_parandamine.sql` | Parandab 26 väärtuse-, nelja teksti- ning kahe kategooria/tüübi veeru vead | Kõigi 32 sihtveeru `alles_vigaseid_lahtrid` = 0; skript lõppes veata |
| 05 | `003.04_mangaa_raud_jood_nihe.sql` | Parandab esmalt kolm mangaani kirjaviga, seejärel Mn/Fe/I nihked | Mangaan 378, raud 1, jood 1 sihtrida; igal toitainel `veel_vigaseid_ridu` = 0 |
| 06 | `004.01_loppkontroll.sql` | Kinnitab mahu, võtmete, struktuuri ja paranduste lõppseisu | Kõik allolevad nõutud tulemused klapivad |

Etappide numbrid 01–06 on kirjas ka failide päistes. Vanad numbrid P2_01–P2_23 kirjeldavad varasemat tööd ega ole selle komplekti eraldi käivitussammud.

## CSV import DBeaveris

1. Pärast etappi 01 värskenda objektipuud ja vali tabel `vet_analytics.vet_raw`.
2. Paremklõps → **Import Data** → **CSV**. Vali kaasas olev algfail.
3. Seaded: **UTF-8**, eraldaja **koma**, jutumärk **"**, esimene rida sisaldab veerupäiseid.
4. Siht on olemasolev tühi `vet_raw`; hoia kõik 215 veergu **TEXT** tüüpi. Tühjad lahtrid võivad olla NULL; neid ei muudeta automaatselt nullarvuks.
5. Vaata veergude vastendus üle. Enamik päiseid ühtib nime järgi; kahe pika päise vastendus on järgmises tabelis.
6. Käivita import üks kord. Salvesta impordi kokkuvõte: ridade ja vigade arv. Käivita etapp 02.

Kordusimport olemasolevate ridade peale tekitab duplikaadid. Impordikontroll peatab sellise sisendi kasutamise; ära jätka töökoopia loomisega.

### Kaks pikka päist

PostgreSQL-i standardse seadistuse korral on tabeli/veerunime piir 63 baiti. Algne loomiskood kasutab CSV täielikke päiseid ja server lühendab kaks liiga pikka nime. See on olemasoleva koodi käitumine; käesolev muudatus ei nimeta veerge ümber. Impordis vali mõlemale CSV päisele selle lühendatud sihtveerg.

| CSV täielik päis | PostgreSQL-i sihtveerg |
|---|---|
| `Tuotekategoria: 0. Täysravinto, 1. herkut, puruluut jne., 2. Täydennysravinto, 3. Öljyt 4. Elintarvikkeet, 5. BARF, 6. Lisäravinteet` | `Tuotekategoria: 0. Täysravinto, 1. herkut, puruluut jne., 2. T` |
| `0.. kuivaruoka, 1. Puolikostea, 2. Märkäruoka, 3. Lisäravinne, 4. BARF 5. Elintarvike` | `0.. kuivaruoka, 1. Puolikostea, 2. Märkäruoka, 3. Lisäravinn` |

Ka päised `minerals.calsium.value`, `vitamins..b1_vitamin.value` ja `dry_matter..value` säilivad algkujul. Topeltpunktide parandamine tähendab **lahtrite sisu**, mitte päiste muutmist.

## Paranduste ja kontrollide tõlgendamine

### Topeltpunktid

Etapp 04 muudab ainult kinnitatud 32 veeru `number..number` mustrit: näiteks `106..6666` → `106.6666` ja `0..5%` → `0.5%`. Veergude valik vastab saadetud paranduskoodidele. Püsiva `value_text_anomalies` tabeli loomine ei ole vajalik; enne/pärast tulemused võetakse sellest käivitusest ajutisse tabelisse, mis eemaldub COMMIT-i lõpus. Soovi korral ekspordi tulemused enne päringuakna sulgemist.

Eelkontroll loendab **vigaseid lahtreid veergude kaupa**. UPDATE kokkuvõte loendab **muudetud ridu paranduste rühma kaupa**. Ühel tootel võib olla mitu vigast lahtrit ning ta võib esineda mitmes rühmas; rühmade ridade summat ei käsitleta eri toodete arvuna.

Mangaani ühikuveerg ei kuulu nende 32 veeru hulka. Seal olevad kolm numbriteksti kirjaviga parandatakse etapis 05. Seetõttu ei nõuta etapi 04 järel veel kogu tabeli kõigi `number..number` esinemiste arvu nulliks.

### Nihked

Etapp 05 tõstab kinnitatud arvud ühikuväljast väärtusevälja ja seab ühikuks `mg`. Parandus ei teisenda ühikuid mg/kg-ks ega muuda teiste toodete nullväärtusi.

Fail kinnitab kõigepealt, et algandmetes on 378 mangaani, üks raua ja üks joodi sihtrida. Erineva algallika korral annab see vea; ajaloolisi erandireegleid tuleb siis enne kasutamist uuesti hinnata.

Järelkontroll kasutab **algtabelist tuletatud kõiki sihtridu**. Seetõttu näitab see lõpptulemust ka siis, kui korduskäivituse UPDATE enam ühtegi rida ei muuda. Edukalt parandatud käivituse järel võivad UPDATE tulemused kordamisel olla tühjad, kuid järelkontroll peab ikka läbima.

### Lõppkontrolli nõutud tulemused

| Kontroll | Oodatav tulemus |
|---|---|
| Mõlema põhitabeli ridade ja eri ID-de arv | Kummaski 15 202 |
| Puuduvad ID-d ja ID-de erinevus raw/clean vahel | Kõik 0 |
| Veergude arv / mitte-TEXT veerud | Kummaski 215 / 0 |
| Struktuurierinevused | 0 |
| `vet_clean_id_uq` indeks | Tulemuses üks unikaalset indeksit kirjeldav rida |
| `number_topeltpunkt_number_ridu` | 0 |
| Nihke kontroll | Kolm rida: jood 1, mangaan 378, raud 1; igal real vigaseid 0 |
| Viis näiterida | Mangaani väärtused ID-de järgi 0.3, 1.9, 1.5; raud 20; jood 0.71; ühikud mg |
| Tootenimede kontroll | Algse CSV järgi FI puudub 3; FI puudub ja EN olemas 0; mõlemad puuduvad 3 |

`muu_topeltpunktiga_ridu` on eraldi **ülevaatuse näitaja**, mille väärtus võib olla suurem kui null. Vabatekstis võib esineda näiteks `L.I..P.`. Algse CSV kohaliku kontrolli järel jäi selliseid ridu 210. Neid ei parandata automaatselt ega loeta numbrikirjavea kontrolli läbikukkumiseks.

Puuduvad tootenimed on andmekvaliteedi leid, mitte impordiviga. See komplekt ei lisa oletuslikke nimesid. Ingliskeelse varunime kasutamine lõplikus BI allikas tuleb dokumenteerida selle etapi juhendis.

## Valikuline auditifail

`../90_VALIKULISED_KONTROLLID/002.03_audititabeli_tootenimed.sql` on põhijärjekorrast välja tõstetud. See muudab **ainult** olemasoleva `unit_anomalies` auditi tootenimesid ning vajab eelnevalt loodud audititabelit. Kui seda tabelit pole, jäta fail vahele. Selle puudumine ei takista kuue põhifaili kasutamist.

Ühikute sageduse kontroll, reeglitabel ja selle täitmine ei kuulu siia põhietappi. Praegused mg/kg funktsioonid peavad sisaldama oma teisendusreegleid, sealhulgas massiprotsendi teisendust 1% = 10 000 mg/kg; neid funktsioone see komplekt ei muuda.

## Korduskäivitamine ja logimine

Loomisfailid 001.01 ja 001.04 käivitatakse üks kord: olemasolev skeem/tabel põhjustab vea. Kontrollfaile 001.03 ja 004.01 saab uuesti käivitada. Parandusfaile saab samadel andmetel korrata, kuid tühja UPDATE väljundi asemel hinnatakse järelkontrolli.

Iga tegeliku sammu kohta täida `../00_JUHEND_JA_LOGI/varasemad_logid/KAIVITUSLOGI_MALL.csv`: aeg, tegija, sihtbaas, fail, tulemus ja kontrollarvud. Säilita vead ja tulemuste väljavõtted. Failide muutmise logi on `../00_JUHEND_JA_LOGI/varasemad_logid/TOOLOGI_KOODIDE_KONTROLL_2026-10-05.md`.

Skriptide muutmine ei tähenda nende käivitamist sinu andmebaasis. Selle komplekti parandusi võrreldi kohalikes failides algse CSV ja 28.09 puhastatud kontrollpunktiga; PostgreSQL-i serveris tervikläbimist ei ole siin tehtud. Märgi päris proovitaastamine läbituks alles pärast kuue faili edukat käivitamist ja lõppkontrolli kinnitamist.

## Failide asukohad

| Kaust | Sisu |
|---|---|
| `00_ALGANDMED` | Algne puhastamata CSV |
| `sql` | Kuus põhifaili |
| `../00_JUHEND_JA_LOGI/varasemad_logid` | Muudatuste logi ja tegeliku käivituse mall |
| `../90_VALIKULISED_KONTROLLID` | Olemasoleva ühikuauditi nimede täiendus |
| `../99_ARHIIV_EI_KAIVITA/SAABUNUD_ALGFAILID` | Seitse saadetud algfaili muutmata kujul; neid ei käivitata uuesti |

## Seos tulevase tervikjuhendiga

Ühenda see peatükk tervikjuhendisse kui **algse CSV taastamisviisi importimise ja puhastamise etapp**. Selle lõpptulemus on `vet_analytics.vet_clean`. Järgmise osa alguses peab olema selgelt kirjas mg/kg teisendusfunktsioonide ja tabeli loomine, teisenduste kontroll, `vet_clean_bi` loomine ning alles siis koostisosad ja `vet_powerbi` mudel. Kontrollpunktist või täielikust varukoopiast alustamine kirjeldatakse eraldi haruna.

## Tehniliste täpsustuste allikad

- [PostgreSQL: nimede pikkus ja lühendamine](https://www.postgresql.org/docs/18/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIERS).
- [PostgreSQL: regulaaravaldise ettevaade ja tagasivaade](https://www.postgresql.org/docs/18/functions-matching.html#POSIX-SYNTAX-DETAILS).
- [PostgreSQL: sama rea korduv uuendamine ühe WITH-lause sees](https://www.postgresql.org/docs/18/queries-with.html#QUERIES-WITH-MODIFYING).
