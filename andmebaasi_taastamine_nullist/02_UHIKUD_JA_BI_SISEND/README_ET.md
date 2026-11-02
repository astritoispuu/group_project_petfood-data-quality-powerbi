# 02. Ühikud ja Power BI sisendtabel

Algse teisendusloogika, kordajad ja 49 toitaine vastendust koostas **Oksana**. Tema lahendus säilib. Üksikasjalik olemasolev ingliskeelne juhend on [README.md](README.md).
Käivita `sql` kaustas: `00_check_vet_clean.sql` → `01_create_functions.sql` → `02_create_normalized_table.sql` → `03_validation.sql` → `04_AINULT_mg_kg.sql`. Iga fail käivita tervikuna. Enne seda peab etapp 01 olema lõpetatud. Kontrollnäited asuvad `optional/05_function_checks.sql`.

Tulemused: `vet_clean_mg_kg` sisaldab kõiki 215 lähteveeru ja 49 uut numeric veergu. `vet_clean_bi` säilitab tooteandmed ja 49 mg/kg veergu ning eemaldab lähteandmete `.value`, `.valu`, `.unit` väljad. Mõlemas on 15 202 toodet.

Teisendamata sisaldus jääb NULL-iks ning ilmub kontrolltulemustes; NULL ei tähenda puuduvat toitainet. Massiühikute `mg`, `g`, `µg` ja `IU/IE` korral säilib projekti eeldus, et kogus on kilogrammi kohta. E-vitamiini IU kordaja 1 säilib Oksana koodis all-rac-alpha-tocopheryl acetate eeldusega. `mg/100g`, `IU/kg` ja energiapõhiseid ühikuid ei lisata vaikimisi uute reeglitena. Vaata normaliseerimise ülevaatust enne arvude kasutamist aruandes.

`numeric` ei ümarda kolme komakohani: väikesed kogused säilivad. Power BI kuvavormingus vali vähemalt kolm komakohta, vajadusel rohkem. Seejärel jätka kausta 03.
