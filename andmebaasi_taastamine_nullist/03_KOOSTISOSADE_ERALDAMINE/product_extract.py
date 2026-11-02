"""Extract ingredient rows from PostgreSQL.

Original code and extraction rules by Astrit.
Standardized on 2026-10-05; see README_EN.md and the AST-ING change log.
"""

import os
import re
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text, URL, inspect


# ============================================================
# 1. POSTGRESQL CONNECTION
# ============================================================

load_dotenv(Path(__file__).with_name(".env"))

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

# Validate connection settings without printing passwords.
required_settings = {
    "DB_HOST": DB_HOST, "DB_NAME": DB_NAME,
    "DB_USER": DB_USER, "DB_PASSWORD": DB_PASSWORD
}
missing_settings = [name for name, value in required_settings.items() if not value]
if missing_settings:
    raise RuntimeError("Missing .env settings: " + ", ".join(missing_settings))
try:
    DB_PORT = int(DB_PORT)
except ValueError:
    raise RuntimeError("DB_PORT must be an integer.") from None

connection_url = URL.create(
    drivername="postgresql+psycopg2",
    username=DB_USER,
    password=DB_PASSWORD,
    host=DB_HOST,
    port=DB_PORT,
    database=DB_NAME
)

engine = create_engine(connection_url)

with engine.connect():
    print("PostgreSQL connection established.")


# ============================================================
# 2. READ SOURCE DATA FROM POSTGRESQL
# ============================================================

INPUT_SCHEMA = "vet_analytics"
INPUT_TABLE = "vet_clean_mg_kg"

# Validate the specified source table without guessing an alternative.
try:
    available_columns = {
        column["name"] for column in inspect(engine).get_columns(
            INPUT_TABLE, schema=INPUT_SCHEMA
        )
    }
    missing_columns = {
        "_id", "product_name_fi", "product_name_en", "product_content"
    } - available_columns
    if missing_columns:
        raise RuntimeError("Missing source columns: " + ", ".join(sorted(missing_columns)))
except Exception:
    engine.dispose()
    raise

query = f"""
SELECT
    _id,
    product_name_fi,
    product_name_en,
    product_content
FROM {INPUT_SCHEMA}.{INPUT_TABLE}
"""

print("SQL query:")
print(query)

try:
    df = pd.read_sql_query(
        query,
        engine
    )
except Exception as e:
    engine.dispose()
    raise RuntimeError(
        f"Failed to read {INPUT_SCHEMA}.{INPUT_TABLE}.\n{e}"
    )

print("\nSOURCE DATA LOADED")
print("=" * 60)
print(f"Source: {INPUT_SCHEMA}.{INPUT_TABLE}")
print(f"Products: {len(df)}")
print(f"Columns: {len(df.columns)}")


# ============================================================
# SETTINGS
# ============================================================

# Text in parentheses:
# "join"    - remove parentheses, keep their content in the same ingredient
# (e.g. "rasv (kana)" -> "rasv kana")
# "extract" - keep parenthesized content as separate ingredients
# (e.g. "rasv (kana)" -> "rasv" and "kana")
# "remove"  - discard parenthesized content
PARENTHESES_MODE = "join"

# Whether to keep E-numbers (e.g. e322) as ingredients
KEEP_E_NUMBERS = True


# ============================================================
# 3. EXCLUDED VALUES
# ============================================================

EXCLUDE_KEYWORDS = {
    "ash", "moisture", "convertible_energy",
    "vitamins", "a_vitamin", "b1_vitamin", "b2_vitamin",
    "b6_vitamin", "b12_vitamin", "d3_vitamin", "e_vitamin",
    "pantothenic_acid", "niacin", "folic_acid", "biotin",
    "trace_elements", "zinc", "copper", "copper_sulfate",
    "minerals", "calsium", "phosphorus", "magnesium",
    "sodium", "potassium", "iodine", "manganese",
    "selenium", "aminoacids", "lysine", "metioniini",
    "tauriini", "arginiini", "rauta", "ie", "ky", "iu",
    "kcal", "kg", "tuhka", "kosteus", "energia",
    "epa", "epadha", "irish farmed", "hydrolysoidut", "tuoretta", "animal",
}


# ============================================================
# 4. PHRASES TO REMOVE
# ============================================================

REMOVE_PHRASES = [

    # ------------------------------------------------------------
    # Regex phrases
    # ------------------------------------------------------------

    r"additives or artificial flavors",
    r"additives or fillers",
    r"natural ingredients?",
    r"british and irish farmed",
    r"freshly prepared",
    r"tasty cuts in gravy",
    r"<br\s*/?>\s*<br\s*/?>",
    r"<strong>",
    r"alu dish",
    r"\*100-prosenttisesti valvottua luomutuotantoa",
    r"¹from an msc certified sustainable fishery",
    r"a novel and delicious source of omega fatty acids which support digestive function",
    r"delicious source of omega fatty acids which support digestive function",
    r"a powerful adaptogenic herb that has protective properties for the kidneys and heart",
    r"a natural multivitamin blend to support your dog's daily nutritional needs",
    r"a pinch of love",
    r"br\s*><br\s*>",
    r"† ingredients thermally pre",
    r"a good soluble",
    r"a meat only",
    r"a novel",
    r"a powerhouse herb",
    r"active system",
    r"adult recipe",
    r"aktiivisuustason mukaan",
    r"analytical constituents\s*%?",
    r"analyyttiset aineosat",
    r"analyyttiset ainesosat",
    r"analyyttiset komponentit",
    r"as well as calcium",
    r"balanced food made",
    r"barf diets",
    r"calorie content",
    r"cooking accessories",
    r"drumstick shape kibbles",
    r"feeding accessories",
    r"fillet / gravy ratio",
    r"freshly pre",
    r"gallbladder function",
    r"green lipped",
    r"has calming",
    r"high meat",
    r"immune health",
    r"immune system",
    r"improves digestion",
    r"ingredients natural origin",
    r"joint care",
    r"joint herb",
    r"just pour",
    r"katsо pakkaus",
    r"keeps stools firm",
    r"kibble to",
    r"koostuu seuraavista",
    r"kilogrammaa kohti",
    r"made in the uk",
    r"main ingredient",
    r"meatfree stock",
    r"no added colours",
    r"no grain",
    r"nutrient absorption",
    r"quality ingredients",
    r"slow baked kibble",
    r"supports digestive wellbeing",
    r"supports gut microflora balance",
    r"supports optimal digestive function",
    r"supports optimal renal function",
    r"taattu analyysi",
    r"tender cuts",
    r"tripod shape kibbles",
    r"typical product composition",
    r"valittu hiilihydraattilähde",
    r"wet food",
    r"\bnaturally\s+derived\b",
    r"\bactive\s+system\b",
    r"\brich\s+in\b",
    r"\bsupports\s+a\s+digestive\s+system\b",
    r"\bsupports\s+a\s+intestinal\s+flora\b",
    r"\bsupports\s+a\s+stomach\s+lining\b",
    r"\bsupports\s+the\s+liver\b",
    r"\bthe\s+supports\s+skin\b",
    r"\bwhich\s+is\s+rich\s+in\b",
    r"\bit\s+is\s+rich\s+in\b",
    r"\bpurenatural\s+kitten\s+chicken\b",
    r"\bpurenatural\s+cat\s+kitten\s+beef\b",
    r"\bsupports\s+a\s+digestive\b",
    r"\bsupports\s+a\b",
    r"\bactive\s+maito\b",
    r"the supports skin",
    r"​​​​​​lajinomaisesti kasvatettu",
    r"animals of which ",
   
    # ------------------------------------------------------------
    # General categories / unspecified ingredients
    # ------------------------------------------------------------

    r"\bkivennäisaineet\b",
    r"\bmineraalit\b",
    r"\bkivennäiset\b",

    r"\böljyt\b",
    r"\brasvat\b",
    r"\bfats\b",
    r"\boils\b",

    r"\bvitamiinit\b",

    r"\bviljat\b",
    r"\bvilja\b",
    r"\bcereals\b",

    r"\bvegetables\b",
    r"\bhedelmät\b",

    r"\buute\b",

    r"\blisäaineet\b",
    r"\bravitsemukselliset\s+lisäaineet\b",

    r"\bvegetable\s+protein\s+extracts\b",
    r"\bkasviproteiiniuutteet\b",

    r"\bderivatives\s+of\s+vegetable\s+origin\b",
    r"\bfish\s+derivatives\b",

    r"\bniiden\s+osat\b",
    r"\baine\b",

    r"\bhehkutusjäännös\b",

    r"\bsisältää\s+luonnollisia\s+antioksidantteja\b",

    r"\bravintosisältö\b",
    r"\bproteiinilähteet\b",
    r"\beläinperäisiä\s+tuotteita\b",
    r"\brasvapitoisuus\b",

    r"\bof\s+the\s+product\b",
    r"\btotal\s+content\s+in\s+product\b",
    r"\bproducts\b",
    r"\bderivatives\b",
    r"\bsources\b",
    r"\bproduct\b",
    r"\bchunksingredients\b",
    r"\btwo\b",
    r"\bresponsibly\s+sourced\b",
    r"\bsustainably\s+sourced\b",
    r"\boriginchunks\b",
    r"\bchunks\s+rich\s+in\b",

    # ------------------------------------------------------------
    # Plant derivatives
    # ------------------------------------------------------------

    r"\bkasviperäiset\s+tuotteet\b",
    r"\bkasviperäiset\s+sivutuotteet\b",
    r"\bkasviperäiset\s+johdannaiset\b",
    r"\bkasviperäiset\s+aineet\b",
    r"\bkasviperäiset\s+aineosat\b",
    r"\bkasviperäiset\s+ainesosat\b",
    r"\bkasviperäiset\s+sivuaineet\b",
    r"\bkasviperäiset\s+derivaatit\b",
    r"\bkasviperäiset\s+sivutuottee\b",
    r"\bkasviperäiset\s+proteiiniuutteet\b",
    r"\bkasviperäiset\b",

    # ------------------------------------------------------------
    # Vegetable derivatives
    # ------------------------------------------------------------

    r"\bkasvisperäiset\s+tuotteet\b",
    r"\bkasvisperäiset\s+tuotteita\b",
    r"\bkasvisperäiset\s+sivutuotteet\b",
    r"\bkasvisperäiset\s+johdannaiset\b",
    r"\bkasvisperäiset\s+aineet\b",
    r"\bkasvisperäiset\s+aineosat\b",
    r"\bkasvisperäiset\s+ainesosat\b",
    r"\bkasvisperäiset\s+öljyt\b",
    r"\bkasvisperäisetsivutuotteet\b",
    r"\bkasvisperäisettuotteet\b",
    r"\bkasvissivutuotteet\b",

    # ------------------------------------------------------------
    # Vegetable terms
    # ------------------------------------------------------------

    r"\bvihannesperäiset\s+sivutuotteet\b",
    r"\bvihannesten\s+sivutuotteet\b",

    # ------------------------------------------------------------
    # Derivatives / vegetables / eggs / milk / fish
    # ------------------------------------------------------------

    r"\bsoseutetut\s+suomalaiset\s+kasvikset\b",
    r"\bsoseutetut\s+kasvikset\b",
    r"\bhapatetut\s+kasvikset\b",
    r"\bhydrolysoidut\s+kasvikset\b",

    r"\bkasvikset\s+vihannesperäiset\s+johdannaiset\b",
    r"\bkasvikset\b",

    r"\bmunan\s+johdannaiset\b",
    r"\bmunajohdannaiset\b",
    r"\bkananmunajohdannaiset\b",

    r"\bmaitojohdannaiset\b",
    r"\bmaidon\s+johdannaiset\b",

    r"\bkalan\s+johdannaiset\b",
    r"\bkalajohdannaiset\b",

    r"\bvihannesjohdannaiset\b",
    r"\bkasvisjohdannaiset\b",

    r"\beläinjohdannaiset\b",

    # ------------------------------------------------------------
    # Animal derivatives
    # ------------------------------------------------------------

    r"\beläinperäiset\s+tuotteet\b",
    r"\beläinperäiset\s+tuotteitat\b",
    r"\beläinperäiset\s+sivutuotteet\b",
    r"\beläinperäiset\s+johdannaiset\b",
    r"\beläinperäiset\s+ainesosad\b",
    r"\beläinperäiset\s+ainesosat\b",
    r"\beläinperäiset\s+proteiinit\b",
    r"\beläinperäiset\s+rasvat\b",
    r"\beläimistä\s+saatavat\s+sivutuotteet\b",

    # ------------------------------------------------------------
    # Animal products - specific variants
    # ------------------------------------------------------------

    r"\beläinperäiset\s+tuotteet\s+paloissa\b",
    r"\beläinperäiset\s+tuotteet\s+filepaloina\b",
    r"\beläinperäiset\s+tuotteet\s+fileinä\b",
    r"\beläinperäiset\s+tuotteet\s+fileepaloissa\b",
    r"\beläinperäiset\s+sivutuotteet\s+fileinä\b",
    r"\beläinperäiset\s+sivutuotteet\s+naudasta\b",
    r"\beläinperäiset\s+tuotteet\s+naudasta\b",
    r"\beläinperäiset\s+tuotteet\s+kalkkunasta\b",
    r"\beläinperäiset\s+tuotteet\s+ankasta\b",

    # ------------------------------------------------------------
    # Meat / meat products / by-products
    # ------------------------------------------------------------

    r"\blihan\s+sivutuotteet\b",
    r"\blihan\s+sivutuotteet\s+naudasta\b",
    r"\blihansivutuotteet\b",
    r"\blihatuotteet\b",
    r"\blihaperäiset\s+tuotteet\b",

    r"\bsianlihan\s+sivutuotteet\b",
    r"\bsian\s+sivutuotteet\b",
    r"\bnaudan\s+sivutuotteet\b",
    r"\bkalkkunan\s+sivutuotteet\b",
    r"\bkanan\s+sivutuotteet\b",

    r"\blohen\s+sivutuotteet\b",
    r"\bsiipikarjan\s+sivutuotteet\b",

    # ------------------------------------------------------------
    # Fish / fish products / by-products
    # ------------------------------------------------------------

    r"\bkalan\s+sivutuotteet\b",
    r"\bkalansivutuotteet\b",
    r"\bkalaperäiset\s+tuotteet\b",
    r"\bkalaperäiset\s+sivutuotteet\b",
    r"\bkalaperäiset\s+sivutuotteet\s+kappaleina\b",
    r"\bkalaperäiset\s+tuotteet\s+fileinä\b",
    r"\bkalaperäiset\s+johdannaiset\b",
    r"\bkalasta\s+saatavat\s+sivutuotteet\b",

    r"\bkalatuotteet\b",
    r"\bkalatuotteet\s+tuotteet\b",

    # ------------------------------------------------------------
    # Milk / eggs / yeast / potato / bakery and dairy products
    # ------------------------------------------------------------

    r"\bmaitotuotteet\b",
    r"\bmeijerituotteet\b",
    r"\bmunatuotteet\b",
    r"\bkananmunatuotteet\b",
    r"\bhiivatuotteet\b",
    r"\bperunatuotteet\b",
    r"\bleipomotuotteet\b",
    r"\bleivontatuotteet\b",
    r"\bmaustetuotteet\b",

    # ------------------------------------------------------------
    # Other by-products / blood products
    # ------------------------------------------------------------

    r"\bsivutuotteet\b",
    r"\bkananmunasivutuotteet\b",
    r"\bverituotteet\b",
    r"\bsianlihan\s+verituotteet\b",
    r"\bporsaan\s+verituotteet\b",

    # ------------------------------------------------------------
    # Single word
    # ------------------------------------------------------------

    r"\btuotteet\b",
    r"\bsourced\b",
    r"\bnaturally\b",

    # ------------------------------------------------------------
    # Misspelled / joined variants
    # ------------------------------------------------------------

    r"kas¬viperäiset\s+tuotteet",
]

# Remove duplicates; dict.fromkeys preserves order.
# Place longer patterns first because regex alternation
# selects the first matching alternative rather than the longest match.
REMOVE_PHRASES = sorted(
    dict.fromkeys(REMOVE_PHRASES),
    key=len,
    reverse=True
)

PHRASE_PATTERN = re.compile(
    "|".join(REMOVE_PHRASES),
    re.IGNORECASE
)


# ============================================================
# 5. WORDS AND PHRASES TO REMOVE
# ============================================================

REMOVE_WORDS = [
    "recepie", "tai", "koostumus", "minimum", "min",
    "from", "additives", "british", "fillets", "atlantic",
    "delicious", "dha", "mcg/kg", "µg/ml", "a mcg",
    "mcg", "µg", "ml", "mg", "kg", "g", "%",
    "kuivattu", "per", "gkg", "mgkg", "inaktiv", "iu",
    "fresh", "meal", "chunks", "a tasty mix of",
    "tasty mix of", "a rich source of", "rich source of",
    "called", "fibre", "a fantastic", "fantastic",
    "source of", "mcgkg", "contains", "dried",
    "free range", "sun", "mar", "¹chunks", "alfa",
    "amb", "and", "anti bacterial", "anti viral",
    "anticancer", "ara", "ateria", "avintoarvot",
    "bht", "bottle", "calories", "cats", "coat",
    "coat health", "complemented", "complete",
    "composition", "cooked", "crude fiber", "digest",
    "digestion", "distilled", "dog mix", "energy",
    "enhanced", "equivalent to", "food", "formulated",
    "healthy", "high", "high in", "ingredients",
    "kibble", "kissa", "koiraa", "koirien",
    "koirille", "kokonainen", "kosteusprosentti",
    "kuivattuja mustikoita", "kuivatut", "kuoret",
    "kuori", "kuorittu", "made", "natural",
    "nourishing", "organic", "original", "pack",
    "packed", "paino n", "parasta ennen", "premium",
    "preserved", "raaka", "raw", "raw food", "recipe",
    "single", "single protein", "strong", "valmistaja",
    "valmistusaineet", "vegan", "kuivattua",
    "friendly", "scottish", "seasonal",
    "hand netted river trout", "loch reared",
    "in the slow baked kibble", "fresh aberdeen",
    "freeze dried free range", "flaked", "in donut",
    "free run irish", "free", "in fillets",
    "gravy", "by", "fed", "finnish", "feel good",
    "farm reared", "which support digestive function",
    "etelämantereen", "especially", "esigelatinoitu",
    "hydrolysate", "in savoury gravy", "whole",
    "good", "in every", "dehydratoituja",
    "dehydratoitua", "dehydratoidut", "dehydrated",
    "dehulled", "norwegian", "ground",
    "deboned free range", "deboned", "crude",
    "powder", "cooked flaked", "cold pressed",
    "pouch", "clear", "chunks rich in", "variant",
    "stock", "sauce", "in broth", "chicken potato vegetables",
    "for mature cats", "for kittens", "shredded fillets",
    "meals", "in jelly", "ham", "added", "alaskan",
    "as a", "awith", "based", "chelated",
    "vitamins", "minerals", "broth", "various", "origin",
]

# Place longer expressions first ("high in" before "high")
# to avoid leaving "in" behind.
REMOVE_WORDS = sorted(
    dict.fromkeys(REMOVE_WORDS),
    key=len,
    reverse=True
)

# Lookarounds also delimit expressions containing symbols such as % or µg,
# where ordinary word boundaries do not work.
WORD_PATTERN = re.compile(
    r"(?<!\w)(" + "|".join(map(re.escape, REMOVE_WORDS)) + r")(?!\w)",
    re.IGNORECASE
)


# ============================================================
# 6. TEXT REPLACEMENTS
# ============================================================

TEXT_REPLACEMENTS = {
    r"brewers'?\s*yeast extract|brewersâ’ yeast extract": "yeast extract",
    r"luomusika": "sika",
    r"luomukala": "kala",
    r"luomukana": "kana",
    r"almistettu perinteisell[ãä]¤?\s*kuivaamismenetelm[ãä]llã¤?\s*naudan nahasta ilman lisã¤aineita": "nauta",
    r"almistettu perinteisellä kuivaamismenetelmällä naudan nahasta ilman lisäaineita": "nauta",
    r"kala[ãö]ljy\s*[–\-—â€“]+\s*omega": "kalaöljy",
    "cerealsvegetables mineralsvarious sugars": "cereals, vegetables, minerals, sugars",
}


# ============================================================
# 7. PROTECTED PATTERNS (omega-3, E-numbers)
# ============================================================
# Splitting would normally separate hyphens and digits.
# Protect terms such as omega-3 and e322 before splitting
# with placeholders (digits to uppercase letters, hyphen to X),
# then restore them afterwards.

PROTECT_PREFIX = "zzprot"
_TO_LETTERS = str.maketrans("0123456789-", "ABCDEFGHIJX")
_TO_DIGITS = str.maketrans("ABCDEFGHIJX", "0123456789-")

OMEGA_PATTERN = re.compile(r"\bomega[\s-]?(3|6|9)\b")
E_NUMBER_PATTERN = re.compile(r"\be-?(\d{3,4}[a-i]?)\b")
PROTECTED_TOKEN_PATTERN = re.compile(PROTECT_PREFIX + r"([a-zA-Z]+)")


def protect_special_terms(text_value):
    text_value = OMEGA_PATTERN.sub(
        lambda m: PROTECT_PREFIX + f"omega-{m.group(1)}".translate(_TO_LETTERS),
        text_value
    )

    if KEEP_E_NUMBERS:
        text_value = E_NUMBER_PATTERN.sub(
            lambda m: PROTECT_PREFIX + f"e{m.group(1)}".translate(_TO_LETTERS),
            text_value
        )

    return text_value


def restore_special_terms(text_value):
    return PROTECTED_TOKEN_PATTERN.sub(
        lambda m: m.group(1).translate(_TO_DIGITS),
        text_value
    )


# ============================================================
# 8. PARENTHESIZED TEXT
# ============================================================

def handle_parentheses(text_value):
    """Join, extract, or remove parenthesized content, including nested groups."""
    if PARENTHESES_MODE == "join":
        replacement, leftover = r" \1 ", " "
    elif PARENTHESES_MODE == "extract":
        replacement, leftover = r",\1,", ","
    else:
        replacement, leftover = "", ","

    previous = None
    while previous != text_value:
        previous = text_value
        text_value = re.sub(r"\(([^()]*)\)", replacement, text_value)

    # Unmatched parentheses
    return text_value.replace("(", leftover).replace(")", leftover)


# ============================================================
# 9. PROCESSING FUNCTIONS
# ============================================================

STATS = {"raw_splits": 0, "removed_duplicates": 0}

SPLIT_PATTERN = re.compile(
    r"[,.:;+&%\-\u2010-\u2015\u2212\ufe58\ufe63\uff0d]+|\d+|\s+with\s+|\s+and\s+|\s+ja\s+|(?<!\w)(?:iii|ii|iv)(?!\w)",
    re.IGNORECASE
)


def clean_ingredient(ing):
    """Clean an ingredient fragment; return None when it should be excluded."""

    ing_clean = ing.strip()

    # Known marketing phrases
    if ing_clean.lower() in ["active system", "the supports skin"]:
        return None

    # Phrases and words
    ing_clean = PHRASE_PATTERN.sub("", ing_clean)
    ing_clean = WORD_PATTERN.sub("", ing_clean)

    # Special characters
    ing_clean = ing_clean.replace("*", "")
    ing_clean = ing_clean.replace("†", "")
    ing_clean = ing_clean.replace("~", "")

    # Remaining descriptive words
    ing_clean = re.sub(r"luomu", "", ing_clean, flags=re.IGNORECASE)

    ing_clean = re.sub(
        r"^with\s+|\bin\s+jelly\b|\bjelly\b|\bwhole\b",
        "",
        ing_clean,
        flags=re.IGNORECASE
    )

    ing_clean = re.sub(
        r"säilöntäaineita|aberdeen|afrikkalaista|alaskan|animal\s+derivatives",
        "",
        ing_clean,
        flags=re.IGNORECASE
    )

    # Digits (protected placeholders contain none)
    ing_clean = re.sub(r"\d+", "", ing_clean)

    # Superscript digits and leading possessive fragments
    ing_clean = re.sub(r"[⁰¹²³⁴⁵⁶⁷⁸⁹]+", "", ing_clean)
    ing_clean = re.sub(r"^\s*['’‘`´]s\b\s*", "", ing_clean)

    # Whitespace and punctuation
    ing_clean = re.sub(r"\s+", " ", ing_clean).strip()
    ing_clean = ing_clean.strip('.,:;-–—―‒‐_*+;\\/<>‘? "()[]=!%†~')
    ing_clean = re.sub(r"\s+", " ", ing_clean).strip()

    # Remove isolated letters before a word
    ing_clean = re.sub(r"^(?:[a-zäöå]\s+)+", "", ing_clean).strip()

    # Collapse repeated adjacent words: "beef beef" -> "beef"
    ing_clean = re.sub(r"\b(\w+)(?:\s+\1\b)+", r"\1", ing_clean, flags=re.IGNORECASE)

    # Empty values
    if not ing_clean:
        return None

    # Exclude values without letters
    if not re.search(r"[^\W\d_]", ing_clean):
        return None

    # Exclude remaining digits before restoring protected terms
    if re.search(r"\d", ing_clean):
        return None

    # Restore protected terms (omega-3, e322)
    ing_clean = restore_special_terms(ing_clean)

    # Descriptive expressions and non-ingredient phrases
    if re.search(
        r"\blähde\b|\blähteet\b|\blähteitä\b|\bsource\b|\bsupport\b"
        r"|\bhelposti\b|\bsulavat\b|\bvitamin\b|\bvitamiini\b",
        ing_clean,
        flags=re.IGNORECASE
    ):
        return None

    # Overly long fragments
    if len(ing_clean.split()) > 4:
        return None

    # General filters
    if (
        len(ing_clean) < 2
        or ing_clean.isdigit()
        or ing_clean.startswith("ei ")
        or ing_clean == "ei"
        or ing_clean in EXCLUDE_KEYWORDS
    ):
        return None

    if any(
        ing_clean.startswith(k + " ")
        or ing_clean.endswith(" " + k)
        for k in EXCLUDE_KEYWORDS
    ):
        return None

    return ing_clean


def extract_ingredients(raw_value):
    """
    Return the ingredients of one product without duplicates.
    """

    if pd.isna(raw_value):
        return []

    text_value = str(raw_value)

    if not text_value.strip() or text_value.strip().lower() == "nan":
        return []

    # Step 1. Replace line breaks with commas and lowercase text
    text_lower = re.sub(
        r"[\r\n]+",
        ",",
        text_value.replace("\\r\\n", ",")
                  .replace("\\n", ",")
                  .replace("\\r", ",")
    ).lower()

    # Treat bullet markers as separators
    text_lower = re.sub(r"[•●▪■◦○‣∙·]", ",", text_lower)

    # Step 2. Text replacements
    for old, new in TEXT_REPLACEMENTS.items():
        text_lower = re.sub(old, new, text_lower, flags=re.IGNORECASE)

    # Step 3. Protect omega terms and E-numbers before splitting
    text_lower = protect_special_terms(text_lower)

    # Step 4. Specific marketing phrase
    if "milk thistle" in text_lower and "a powerful antioxidant" in text_lower:
        text_lower = text_lower.replace("milk thistle", "")

    text_lower = text_lower.replace("a powerful antioxidant", "")

    # Step 5. Remove configured phrases
    # (apply phrase removal again to each fragment later)
    text_lower = PHRASE_PATTERN.sub("", text_lower)

    # Step 6. Parenthesized text
    text_lower = handle_parentheses(text_lower)

    # Step 7. Split into ingredients
    raw_ingredients = SPLIT_PATTERN.split(text_lower)

    # Step 8. Clean fragments and remove duplicates
    results = []
    seen = set()

    for ing in raw_ingredients:

        if ing is None:
            continue

        ing_clean = clean_ingredient(ing)

        if ing_clean is None:
            continue

        STATS["raw_splits"] += 1

        # Duplicate ingredients within the same product row
        if ing_clean in seen:
            STATS["removed_duplicates"] += 1
            continue

        seen.add(ing_clean)
        results.append(ing_clean)

    return results


# ============================================================
# 10. RUN EXTRACTION
# ============================================================
# Iterate over columns with zip instead of iterrows.
# This also preserves access to the _id column;
# itertuples would rename a column beginning with an underscore.

all_new_rows = []

for _id, name_fi, name_en, content in zip(
    df["_id"],
    df["product_name_fi"],
    df["product_name_en"],
    df["product_content"]
):
    for ing in extract_ingredients(content):
        all_new_rows.append({
            "_id": _id,
            "product_name_fi": name_fi,
            "product_name_en": name_en,
            "ingredient": ing
        })

df_long = pd.DataFrame(all_new_rows)

# Remove empty ingredients and values consisting only of symbols
if not df_long.empty:
    has_letters = df_long["ingredient"].fillna("").str.contains(r"[^\W\d_]", regex=True)
    df_long = df_long[has_letters].reset_index(drop=True)

# ============================================================
# 11. OUTPUT COLUMN ORDER
# ============================================================

if not df_long.empty:

    columns = [
        "_id",
        "product_name_fi",
        "product_name_en",
        "ingredient"
    ]

    df_long = (
        df_long[columns]
        .sort_values(by="_id", kind="stable")
        .reset_index(drop=True)
    )


# ============================================================
# 12. SAVE OUTPUT TO POSTGRESQL (ONE TRANSACTION)
# ============================================================
# Write a staging table within one transaction,
# then drop the old output and rename the staging table.
# Any failure rolls back the transaction and preserves the old output.

OUTPUT_SCHEMA = "vet_analytics"
OUTPUT_TABLE = "product_ingredients_rows"
TEMP_TABLE = f"{OUTPUT_TABLE}_tmp"
BATCH_SIZE = 500

if not df_long.empty:

    print("\nSAVING OUTPUT TO POSTGRESQL...")
    print("=" * 60)
    print(f"Rows to save: {len(df_long)}")

    total_rows = len(df_long)

    try:
        with engine.begin() as conn:

            conn.execute(text(
                f'DROP TABLE IF EXISTS "{OUTPUT_SCHEMA}"."{TEMP_TABLE}"'
            ))

            for start in range(0, total_rows, BATCH_SIZE):

                end = min(start + BATCH_SIZE, total_rows)
                df_batch = df_long.iloc[start:end]

                df_batch.to_sql(
                    name=TEMP_TABLE,
                    con=conn,
                    schema=OUTPUT_SCHEMA,
                    if_exists="replace" if start == 0 else "append",
                    index=False,
                    method="multi"
                )

                print(f"Written in transaction: {end} / {total_rows} rida")

            conn.execute(text(
                f'DROP TABLE IF EXISTS "{OUTPUT_SCHEMA}"."{OUTPUT_TABLE}"'
            ))
            conn.execute(text(
                f'ALTER TABLE "{OUTPUT_SCHEMA}"."{TEMP_TABLE}" '
                f'RENAME TO "{OUTPUT_TABLE}"'
            ))

    except Exception as e:
        engine.dispose()
        raise RuntimeError(
            "Saving failed; the transaction was rolled back "
            f"(the previous output table is unchanged).\n{e}"
        )

    print("\nOUTPUT COMMITTED")
    print("=" * 60)
    print(f"Table: {OUTPUT_SCHEMA}.{OUTPUT_TABLE}")
    print(f"Saved rows: {len(df_long)}")

else:

    engine.dispose()
    raise RuntimeError(
        "No ingredients were extracted; the previous output table was not changed."
    )


# ============================================================
# 13. SUMMARY
# ============================================================

print("\n")
print("=" * 60)
print("PROCESSING COMPLETE")
print("=" * 60)

print(f"Source rows (products): {len(df)}")
print(f"Accepted candidates before deduplication: {STATS['raw_splits']}")
print(f"Removed duplicates: {STATS['removed_duplicates']}")
print(f"Final rows: {len(df_long)}")
print(f"Output table: {OUTPUT_SCHEMA}.{OUTPUT_TABLE}")
print(f"Parentheses mode: {PARENTHESES_MODE}")

engine.dispose()

print("=" * 60)
print("PostgreSQL connection closed.")