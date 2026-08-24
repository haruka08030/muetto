"""香料の系統（family）分類。

好み分析では香料単体・香調アコード・共起ペアを特徴量にするが、
系統は検索フィルタと UI のグルーピング（色分け）に使う。

分類は「明示辞書 → キーワード規則 → other」の順で決定する。
自動判定に任せきりにせず、頻出語は明示辞書で押さえる。
"""

from __future__ import annotations

FAMILIES = [
    "citrus", "floral", "white_floral", "green", "herbal", "aromatic",
    "fruity", "woody", "spicy", "gourmand", "balsamic", "animalic",
    "musk", "aquatic", "powdery", "earthy", "leather", "tobacco",
    "boozy", "aldehydic", "mineral", "synthetic", "tea", "other",
]

FAMILY_LABELS_JA = {
    "citrus": "シトラス", "floral": "フローラル", "white_floral": "ホワイトフローラル",
    "green": "グリーン", "herbal": "ハーバル", "aromatic": "アロマティック",
    "fruity": "フルーティ", "woody": "ウッディ", "spicy": "スパイシー",
    "gourmand": "グルマン", "balsamic": "バルサミック", "animalic": "アニマリック",
    "musk": "ムスク", "aquatic": "アクアティック", "powdery": "パウダリー",
    "earthy": "アーシー", "leather": "レザー", "tobacco": "タバコ",
    "boozy": "アルコーリック", "aldehydic": "アルデハイド",
    "mineral": "ミネラル", "synthetic": "合成香料", "tea": "ティー",
    "other": "その他",
}

# --- 明示辞書 ----------------------------------------------------------------
EXPLICIT: dict[str, str] = {}


def _add(family: str, *names: str) -> None:
    for n in names:
        EXPLICIT[n] = family


_add("citrus",
     "bergamot", "lemon", "lime", "orange", "bitter orange", "blood orange",
     "mandarin orange", "grapefruit", "yuzu", "citron", "kumquat", "pomelo",
     "petitgrain", "neroli", "citruses", "citrus notes", "key lime",
     "kaffir lime", "finger lime", "lemon zest", "bergamot zest",
     "grapefruit zest", "lemon verbena", "lemon grass", "lemongrass",
     "calamansi", "bigarade", "green lemon", "orange leaf", "bitter orange leaf")

_add("floral",
     "rose", "may rose", "damask rose", "iris", "violet", "peony", "geranium",
     "lavender", "carnation", "mimosa", "heliotrope", "hyacinth", "narcissus",
     "chamomile", "poppy", "lotus", "waterlily", "water lily", "cyclamen",
     "wisteria", "hibiscus", "camellia", "marigold", "clover", "flowers",
     "floral notes", "wild flowers", "blossoms", "exotic blossoms", "tulip",
     "amaryllis", "boronia", "cherry blossom", "apple blossom",
     "peach blossom", "almond blossom", "apricot blossom", "plum blossom",
     "sunflower", "immortelle", "everlasting flower", "rose hip", "saffron blossom",
     "pink rose", "white rose", "black rose", "red peony", "pink peony",
     "white peony", "blue iris", "parma violet", "black violet", "datura")

_add("white_floral",
     "jasmine", "jasmine sambac", "tuberose", "gardenia", "ylang-ylang",
     "orange blossom", "magnolia", "freesia", "lily of the valley", "lily",
     "white lily", "white orchid", "orchid", "frangipani", "champaca",
     "stephanotis", "honeysuckle", "linden", "linden blossom", "linden tree",
     "white lotus", "casablanca lily", "queen-of-the-night", "acacia",
     "sweet acacia", "star jasmine", "gingerlily", "white gingerlily",
     "ginger flower", "kahili ginger", "yellow freesia", "white flowers",
     "aquatic flowers", "olive blossom", "grapefruit blossom", "cactus blossom",
     "orange blossom water")

_add("green",
     "green notes", "grass", "galbanum", "violet leaf", "ivy", "bamboo",
     "bamboo leaf", "fig leaf", "tomato leaf", "leaves", "moss", "fern",
     "seagrass", "shiso", "shiso leaf", "cucumber", "green tea leaf",
     "blackcurrant bud", "currant leaf", "raspberry leaf", "rhubarb leaf",
     "pineapple leaf", "water hyacinth", "cotton", "hay", "grass notes",
     "stems", "sap", "buchu")

_add("herbal",
     "mint", "spearmint", "peppermint", "water mint", "basil", "thyme",
     "white thyme", "rosemary", "sage", "clary sage", "tarragon", "oregano",
     "marjoram", "wormwood", "mugwort", "angelica", "angelica seed", "hyssop",
     "verbena", "herbs", "aromatic herbs", "eucalyptus", "camphor", "yarrow",
     "lovage", "celery", "fenugreek", "turmeric", "calamus", "spikenard",
     "myrtle", "laurel", "bay leaf", "roman chamomile", "aromatic notes")

_add("aromatic", "aromatic notes", "fougere notes", "fougère notes", "coumarin")

_add("fruity",
     "apple", "red apple", "green apple", "pear", "nashi pear", "williams pear",
     "peach", "apricot", "plum", "prune", "cherry", "sour cherry", "raspberry",
     "strawberry", "blackberry", "blueberry", "cranberry", "dewberry",
     "blackcurrant", "red currant", "currant", "berries", "fruits",
     "red fruits", "candied fruits", "dried fruits", "tropical fruits",
     "watery fruits", "exotic fruits", "melon", "honeydew melon", "watermelon",
     "pineapple", "mango", "papaya", "guava", "passionfruit", "lychee",
     "banana", "coconut", "coconut water", "coconut milk", "fig", "fig milk",
     "date", "grape", "kiwi", "quince", "rhubarb", "tamarind", "açaí", "acai",
     "dragon fruit", "pomegranate", "nectarine", "wild peach", "peach skin",
     "apricot nectar", "pear sorbet", "minneola tangelo", "fruity notes")

_add("woody",
     "woody notes", "sandalwood", "cedarwood", "oud", "vetiver", "patchouli",
     "gaiac wood", "rosewood", "birch", "teak", "mahogany", "ebony", "cypress",
     "juniper", "cade juniper", "pine", "stone pine", "siberian stone pine",
     "spruce", "fir", "sequoia", "driftwood", "white woods", "dry woods",
     "dark woods", "olive wood", "fig wood", "cashmeran", "clearwood",
     "georgywood", "amyris", "papyrus", "nagarmotha", "cypriol", "bark",
     "cedar leaf", "white cedar", "chestnut", "black locust", "pittosporum",
     "sequoia wood", "wood notes")

_add("spicy",
     "pepper", "black pepper", "pink pepper", "white pepper", "green pepper",
     "sichuan pepper", "cardamom", "green cardamom", "black cardamom",
     "cinnamon", "cassia", "clove", "nutmeg", "mace", "ginger", "red ginger",
     "saffron", "coriander", "coriander seed", "cumin", "caraway", "anise",
     "star anise", "fennel", "pimento", "allspice", "chili", "paprika",
     "spices", "spicy notes", "carrot seed", "elemi")

_add("gourmand",
     "vanilla", "chocolate", "dark chocolate", "cocoa", "coffee", "caramel",
     "salted caramel", "honey", "white honey", "sugar", "brown sugar",
     "cane sugar", "sugar powder", "almond", "bitter almond", "roasted almond",
     "green almond", "hazelnut", "pistachio", "walnut", "nuts", "praline",
     "marshmallow", "milk", "cream", "creamy notes", "butter", "toffee",
     "nougat", "meringue", "dulce de leche", "rice", "basmati rice", "bread",
     "biscuit", "cake", "popcorn", "maple", "licorice", "dragée",
     "vanilla cream", "french vanilla", "tonka bean", "roasted tonka bean",
     "cotton candy", "whipped cream", "condensed milk", "truffle")

_add("balsamic",
     "balsamic notes", "amber", "benzoin", "labdanum", "frankincense", "myrrh",
     "opoponax", "elemi resin", "resins", "balsam", "fir balsam", "fir resin",
     "gurjum balsam", "peru balsam", "tolu balsam", "copaiba", "mastic",
     "galbanum resin", "amber notes", "amber accord", "beeswax",
     "incense material", "frankincense resin", "mineral amber")

_add("animalic",
     "animalic notes", "civet", "castoreum", "ambergris", "hyraceum",
     "costus", "honey animalic", "skin", "foulness", "deer musk", "indole")

_add("musk",
     "musk", "white musk", "black musk", "musk notes", "ambrette",
     "ambrettolide", "muscenone", "tonkin musk", "tibetan musk", "musks")

_add("aquatic",
     "aquatic", "sea salt", "seawater", "sea notes", "ozonic", "water notes",
     "rain accord", "ice accord", "spindrift", "algae", "seaweed",
     "marine notes", "water", "dew", "mist")

_add("powdery",
     "powdery notes", "talcum", "rice powder", "orris powder", "makeup notes")

_add("earthy",
     "earthy notes", "soil", "mushroom", "lichen", "treemoss", "oakmoss",
     "crystallised moss", "irish moss", "mossy notes", "humus", "petrichor")

_add("leather", "leather", "suede", "white leather", "tuscan leather", "birch tar")

_add("tobacco", "tobacco", "blond tobacco", "tobacco blossom", "pipe tobacco", "smoke")

_add("boozy",
     "rum", "whisky", "whiskey", "cognac", "brandy", "gin", "vodka",
     "champagne", "wine", "beer", "amaretto", "absinthe liqueur",
     "blackcurrant liqueur", "bay rum", "liqueur")

_add("aldehydic", "aldehydes", "aldehydic notes")

_add("mineral", "mineral notes", "flint", "stone", "metallic notes", "gunpowder")

_add("synthetic",
     "ambroxan", "hedione", "iso e super", "cashmeran wood", "paradisone",
     "cascalone", "petalia", "salicylate", "synthetic notes", "helvetolide",
     "javanol", "norlimbanol")

_add("tea", "tea", "green tea", "black tea", "white tea", "maté", "mate",
     "maté tea", "earl grey tea", "matcha", "tea notes")

# --- キーワード規則 -----------------------------------------------------------
# 明示辞書に無い語を、部分一致で推定する。順序が優先度。
KEYWORD_RULES: list[tuple[tuple[str, ...], str]] = [
    (("oud", "agarwood"), "woody"),
    (("wood", "cedar", "sandal", "pine", "cypress", "birch", "vetiver",
      "patchouli", "bamboo wood"), "woody"),
    (("musk",), "musk"),
    (("tea",), "tea"),
    (("tobacco",), "tobacco"),
    (("leather", "suede"), "leather"),
    (("moss", "soil", "earth", "truffle", "mushroom"), "earthy"),
    (("rum", "whisky", "cognac", "brandy", "liqueur", "gin", "vodka",
      "champagne", "wine"), "boozy"),
    (("aldehyd",), "aldehydic"),
    (("blossom", "jasmine", "tuberose", "gardenia", "magnolia", "lily",
      "orchid", "freesia"), "white_floral"),
    (("rose", "violet", "iris", "orris", "peony", "lavender", "geranium",
      "carnation", "mimosa", "narcissus", "hyacinth", "flower", "floral",
      "petal"), "floral"),
    (("lemon", "lime", "orange", "bergamot", "grapefruit", "citrus",
      "mandarin", "citron", "yuzu", "neroli", "petitgrain"), "citrus"),
    (("berry", "apple", "pear", "peach", "plum", "cherry", "melon", "mango",
      "fruit", "fig", "coconut", "banana", "grape", "apricot", "currant",
      "pineapple", "papaya", "guava", "lychee"), "fruity"),
    (("pepper", "cardamom", "cinnamon", "clove", "nutmeg", "ginger",
      "saffron", "spice", "anise", "cumin", "coriander"), "spicy"),
    (("vanilla", "chocolate", "cocoa", "coffee", "caramel", "honey", "sugar",
      "almond", "nut", "milk", "cream", "praline", "candy", "rice",
      "tonka"), "gourmand"),
    (("amber", "benzoin", "labdanum", "incense", "frankincense", "myrrh",
      "resin", "balsam", "balsamic", "beeswax"), "balsamic"),
    (("mint", "basil", "thyme", "sage", "rosemary", "herb", "eucalyptus",
      "wormwood", "angelica", "camphor", "laurel", "myrtle"), "herbal"),
    (("leaf", "grass", "green", "galbanum", "ivy", "fern", "stem",
      "sap"), "green"),
    (("water", "sea", "marine", "aquatic", "ozon", "rain", "algae",
      "salt"), "aquatic"),
    (("powder", "talc"), "powdery"),
    (("ambergris", "civet", "castoreum", "animal", "skin"), "animalic"),
    (("metal", "mineral", "flint", "stone"), "mineral"),
    (("smoke", "smoky", "tar"), "tobacco"),
]


def classify(canonical_name: str) -> str:
    """正規形の香料名から系統を判定する。"""
    name = canonical_name.lower().strip()
    if name in EXPLICIT:
        return EXPLICIT[name]
    for keywords, family in KEYWORD_RULES:
        if any(k in name for k in keywords):
            return family
    return "other"
