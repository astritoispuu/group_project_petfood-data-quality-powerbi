# 90. Valikulised auditid

Need varasemad auditid ei ole tabelite ega BI mudeli loomiseks vajalikud. Põhitaastamise kontrollid on etappides 01–05 ja 07. 

| Fail | Mõju ja eeldus |
|---|---|
| `002.01_uhikute_sageduse_kontroll.sql` | Ajutine ühikute sagedustabel; vajab vet_clean tabelit |
| `002.02_unit_anomalies_loomine.sql` | Loob unit_anomalies; eeldab selle puudumist |
| `002.03_audititabeli_tootenimed.sql` | Täidab eelneva unit_anomalies audititabeli puuduvaid FI/EN nimesid |
| `002.04_value_unit_nihke_audit.sql` | Loob value_unit_shift_anomalies; eeldab selle puudumist |
| `002.05_value_text_anomalies_loomine.sql` | Loob value_text_anomalies; eeldab selle puudumist |

Võid need etapi 01 järel ühekordselt käivitada, kui soovid vanu audititabeleid taastada. Ühikute lubatud loend on ajalooline auditireegel, mitte mg/kg funktsiooni lubatud ühikute leping. CHECK_UNIT tähendab ülevaatamise vajadust. Skriptid ei paranda vet_clean sisaldusi. Olemasolevate audititabelite korral ära käivita loomist uuesti.
