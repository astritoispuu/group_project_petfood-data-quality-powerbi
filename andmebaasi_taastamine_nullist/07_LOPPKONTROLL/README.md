# 07. Tervikpaketi lõppkontroll

Käivita `01_loppkontroll.sql` pärast etappe 01–05. Etapp 06 on analüüsitabeli jaoks valikuline.

Skript on ainult lugemiseks. DO-plokk katkestab vea korral; kontrollib toote- ja näitajamahtusid, koostisosade võtmeid/katvust, kategooriate kooskõla, duplikaate ning kõigi 49 sisaldusnäitaja täpset vastavust kolme tuletatud väljundi vahel. Väikesed arvud 0.0006 ja 0.000025 peavad säilima.

Kaasasoleva CSV korral peavad kõigis neljas analytics tootetabelis ja dim_products tabelis olema 15 202 toodet; dim_nutrients 49 näitajat; fact_product_nutrients 744 898 rida. Koostisosade tegelikud katvuse ja tabelite mahud salvestatakse logisse.

See kontroll ei kinnita kõikide ühikute või kategooriate sisulist õigsust, aruande DAX-i. Need piirid on tervikjuhendis. Uus kontrollskript koostati ChatGPT abil paketi sidumiseks; see ei asenda Oksana, Astriti ega Liina algautorite tööd.
