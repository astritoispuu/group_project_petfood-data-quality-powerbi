
# Power BI dashboardi kujundus

Raport on mõeldud lemmikloomatoitude leidmiseks koostisosade tingimuste järgi ning toodete toitainesisalduse võrdlemiseks. See koosneb neljast lehest:

| Inglise keeles | Eesti keeles |
|---|---|
| **Excluded categories** | Välistamine |
| **Ingredients & Categories** | Kategooriad ja koostisosad |
| **Nutrient Comparison** | Toitainete võrdlus |
| **Suitable Foods** | Sobivad toidud |

## Visuaalne ülesehitus ja värvid

Kujundus on heleda ja tagasihoidliku ilmega. Taustana on kasutatud heleroheline (#E9F0E9) ja helehall (#F6F6F6), tekst on tumehall (#666666) ning tulpdiagrammid tumerohelised (#707B70). Ühtne värvipalett hoiab tähelepanu andmetel. \[Täiendada: filtrite asukoht, kaartide ja diagrammide paigutus, visuaalne hierarhia lehtedel.\]

## Mõõdikukaardid ja ikoonid

Kuna tegemist on meditsiinilise kallakuga **VET-ÄPIGA** on ikoonid puhtad ja minimalistlikud.

**Excluded product count** - ikoon, mis sümboliseerib **eemaldamist, keelamist, filtrit või prügikasti**, andes kasutajale koheselt märku, et need tooted on valikust välja arvatud.

<table width="100%">
  <tr>
    <td width="90" align="center" valign="middle"><img src="images/icons/excluded-product-count.png" alt="Eye-slashed" width="40"></td>
    <td align="left" valign="middle">
      Valitud ikoon: Silm kriipsuga peal (Eye-slashed / Hidden)<br>
      Sümboliseerib andmeteaduses ja äpiraamistikes asju, mis on "ära peidetud" või vaatest välja filtreeritud. Sobib hästi konteksti, kus andmed on mudelist ajutiselt eemaldatud.
    </td>
  </tr>
</table>

**Products that passed the selection** - ikoon, mis sümboliseerib **õnnestumist, rohelist tuld, heakskiitu või puhtaid andmeid**, andes märku, et need tooted on ohutud ja vastavad kõigile sisestatud kriteeriumitele.

<table width="100%">
  <tr>
    <td width="90" align="center" valign="middle"><img src="images/icons/products-passed.png" alt="Shield with a Checkmark" width="40"></td>
    <td align="left" valign="middle">
      Valitud ikoon: Kaitsekilp linnukesega (Shield with a Checkmark)<br>
      Kuna otsitakse lemmikloomale turvalist toitu (nt allergiavaba dieeti), sümboliseerib kilp ohutust ja tervislikkust. See näitab, et need tooted on looma jaoks "turvalised".
    </td>
  </tr>
</table>

**Unique Brands Count -** ikoon, mis sümboliseerib **kaubamärke, tootjaid**, andes loomaarstile märku, kui paljude erinevate tootjate vahel valik jaguneb.

<table width="100%">
  <tr>
    <td width="90" align="center" valign="middle"><img src="images/icons/unique-brands-count.png" alt="Tag / Price Tag" width="40"></td>
    <td align="left" valign="middle">
      Valitud ikoon: Tootemärgis / Silt (Tag / Price Tag) - klassikaline püstine või viltune tootesilt<br>
      Rahvusvahelises disainikeeles (nt <i>Material Design</i> või <i>FontAwesome</i>) sümboliseerib silt brände, kaubamärke.
    </td>
  </tr>
</table>

**Product Count -** ikoon, mis sümboliseerib **valmistooteid**. Kuna tegemist on loenduriga, mis näitab, kui palju *konkreetseid tooteid* (konserve, krõbinaid jne) on alles jäänud, eristub ikoon koostisosade ja brändide sümbolitest.

<table width="100%">
  <tr>
    <td width="90" align="center" valign="middle"><img src="images/icons/product-count.png" alt="Box / Package" width="40"></td>
    <td align="left" valign="middle">
      Valitud ikoon: Tootepakend / Kast (Box / Package)<br>
      Andmetes ja e-kaubanduses tähistab kast füüsilist lõpptoodet. Kuna loendame toote üldarvu (<i>Product Count</i>), loob see visuaalse seose.
    </td>
  </tr>
</table>

**Ingredient Count** - ikoon, mis sümboliseerib **retsepti, koostisosi, elemente või nimekirja**.

<table width="100%">
  <tr>
    <td width="90" align="center" valign="middle"><img src="images/icons/ingredient-count.png" alt="Flask / Beaker" width="40"></td>
    <td align="left" valign="middle">
      Valitud ikoon: Laborikolb või Keeduklaas (Flask / Beaker)<br>
      Laborikolb koostist, keemilisi elemente ja teaduslikku analüüsi. See annab dashboardile meditsiinilise ilme.
    </td>
  </tr>
</table>

**Ingredient Category Count** - ikoon, mis sümboliseerib **grupeerimist, kaustu, hierarhiat või elementide liigitamist**, andes märku, et koostisosad on jagatud suurematesse loogilistesse rühmadesse (nt valgud, rasvad, süsivesikud, vitamiinid jne).

<table width="100%">
  <tr>
    <td width="90" align="center" valign="middle"><img src="images/icons/ingredient-category-count.png" alt="Layers / Stack" width="40"></td>
    <td align="left" valign="middle">
      Valitud ikoon - Kihiline kook / Kastide virn (Layers / Stack)<br>
      Rahvusvahelises disainikeeles sümboliseerivad kihid (<i>Layers</i>) andmete liigitamist, kategooriaid ja struktuuri. See on minimalistlik, IT-pärane ja modernne.
    </td>
  </tr>
</table>

## Kujundus ja lehtede ülesehitus

Kõigil lehtedel on ühesugune **päis**: vasakul käpa ikoon, aruande pealkiri "Pet Food Analytics", lehe nimi paksus kirjas ja lühike selgitus lehe eesmärgist.

**Paremas ülanurgas** asuvad nupud **Reset filters** ja **Info**. Lehtedel 2–4 on lisaks **tagasi-nool**.

**Taustavärvid** on heleroheline (#E9F0E9) ja helehall (#F6F6F6), tekst tumehall (#666666) ja tulpdiagrammid tumerohelised (#707B70). Roheline värv on kasutusel filtripaneelidel, mõõdikukaartidel ja tabelite päistes. Diagrammid ja tabelid asuvad valgel taustal õhukese ääreraamiga. Kujunduses on kasutatud ühtset fonti ja väikest arvu värve.

**Diagrammidel** on väärtused näha tulpade juures ja Nutrient Comparison lehel selgitab diagrammi vaikeseisundit eraldi tekst.

Raport koosneb neljast lehest:

- **Excluded categories - välistamine:** kasutaja valib välistatavad kategooriad ja näeb, millised tooted jäävad valikusse. Vasakul on rohelisel taustal filtripaneel (Species, Brand, Excluded categories). Paremal ülal on kolm mõõdikukaarti (Excluded product count, Products that passed the selection, Unique brands count) ja nende all tootetabel (Product ID, Product name EN, Category).

<img width="1000" alt="excluded-categories" src="https://github.com/user-attachments/assets/95f1cb34-53a6-473c-bde7-329f1dddd3b8" />

  *Joonis 1. Excluded categories*

- **Ingredients & Categories** - **kategooriad ja koostisosad:** ülevaade koostisosadest ja nende kategooriatest. Ülal on kolm mõõdikukaarti (Product Count, Ingredient Count, Ingredient Category Count). Vasakul all on horisontaalne tulpdiagramm "Number of different ingredient names by category", mille tulbad on järjestatud suurimast väikseimani ja väärtused on tulpade otsas. Paremal on kerimisribaga tabel Category–Ingredient.

  ![Ingredients & Categories](images/ingredients-categories.png)

  *Joonis 2. Ingredients & Categories*

- **Nutrient Comparison** - **toitainete võrdlus:** valitud toodete toitainesisalduse võrdlus. Filtrid (Nutrient, Compared Products, Species) asuvad lehe ülaosas horisontaalsel rohelisel ribal. Vasakul on laiendatavate ridadega tabel tootenimedega ja valitud toitaine veerg. Paremal on tulpdiagramm toodete võrdluseks. Diagrammi kohal on kursiivis juhis: kui toitainet pole valitud, näidatakse vaikimisi kaltsiumi sisaldust.

  ![Nutrient Comparison](images/nutrient-comparison.png)

  *Joonis 3. Nutrient Comparison*

- **Suitable Foods - sobivad toidud:** ühendab välistamise, nõutavad koostisosad ja toitainete tingimused, et leida kõigile kriteeriumitele vastavad tooted. Vasakul on filtripaneel (Species, Brand, Excluded ingredient, Must Contain Ingredient). Paremal on tootetabel (Product ID, Product name, Brand). Kuna siin on kombineeritud välistavad ja nõutavad koostisosad, tulevad tulemuseks sobivad tooted.

  ![Suitable Foods](images/suitable-foods.png)

  *Joonis 4. Suitable Foods*

## Kasutajaloogika ja interaktiivsus

Kasutaja valib filtripaneelil liigi (cat/dog nupud), brändi või koostisosa (rippmenüüd) ja tabelid ning kaardid kohanduvad valikule. Lehtedel Excluded ingredients ja Suitable Foods on filtrid vasakul servas, Nutrient Comparison lehel ülal, nii et kõigil lehtedel asuvad filtrid tulemustest vasakul või nende kohal. Nupp **Reset filters** tühistab valikud, **Info** viib selgitava infolehele ja **tagasi-nool** aitab lehelt naasta.
