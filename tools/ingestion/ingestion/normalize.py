"""香料名・香調名の正規化とカノニカル化。

一次ソースの香料名には産地違い・抽出法違いの表記が大量に含まれる。

    Bulgarian rose / Turkish rose absolute / Grasse rose / Rose otto ...

これらをそのままマスタに載せると、好み分析の特徴量が「ローズ」という
1 つの概念に対して十数個に分散してしまい、サンプル件数が確保できなくなる。

そこで修飾語（産地・抽出法・部位）を剥がした正規形を求め、
元の表記は別名（synonym）として保持する。
"""

from __future__ import annotations

import re
import unicodedata

# 産地・原産地を表す修飾語。先頭に付くことが多い。
ORIGIN_QUALIFIERS = {
    "african", "algerian", "amazonian", "arabian", "argentinian", "assam",
    "atlas", "australian", "bahian", "balinese", "borneo", "brazilian",
    "british", "bulgarian", "burmese", "calabrian", "cambodian", "canadian",
    "caribbean", "ceylon", "ceylonese", "chinese", "colombian", "corsican",
    "cuban", "cypriot", "damask", "dutch", "egyptian", "english", "ethiopian",
    "european", "florentine", "french", "gallic", "georgian", "german",
    "grasse", "greek", "guatemalan", "haitian", "himalaya", "himalayan",
    "indian", "indochinese", "indonesian", "iranian", "iraqi", "irish",
    "israeli", "italian", "japanese", "javanese", "kashmiri", "kenyan",
    "korean", "laotian", "madagascan", "madagascar", "malayan", "malaysian",
    "maltese", "mexican", "moroccan", "morrocan", "nepalese", "nootka",
    "omani", "oriental", "pakistani", "papua", "paraguayan", "persian",
    "peruvian", "polish", "portuguese", "roman", "russian", "siberian",
    "sicilian", "singapore", "somali", "spanish", "sri", "sudanese",
    "sumatra", "sumatran", "swiss", "syrian", "tahitian", "taif", "thai",
    "tibetan", "tonkin", "tunisian", "turkish", "tuscan", "venezuelan",
    "vietnamese", "yemeni", "zanzibar",
}

# 抽出法・形態を表す修飾語。末尾に付くことが多い。
FORM_SUFFIXES = [
    "absolute", "absolut", "concrete", "resinoid", "oleoresin", "tincture",
    "co2 extract", "co2", "essential oil", "essence", "extract", "oil",
    "distillate", "otto", "attar", "infusion", "accord", "notes", "note",
    "material", "molecule",
]

# 先頭に付く抽出法・グレード表現。
FORM_PREFIXES = ["wild", "organic", "natural", "pure", "fresh", "dried", "raw"]

# 剥がしてはいけない語。剥がすと別の香料になってしまうもの。
# 例: "Orange blossom" から "blossom" を剥がすと "Orange"（柑橘）になり別物。
PROTECTED = {
    "orange blossom", "cherry blossom", "apple blossom", "peach blossom",
    "almond blossom", "apricot blossom", "olive blossom", "cactus blossom",
    "grapefruit blossom", "saffron blossom", "ginger flower", "orange leaf",
    "violet leaf", "blackcurrant bud", "cedar leaf", "bay leaf", "tea leaf",
    "tobacco leaf", "shiso leaf", "raspberry leaf", "currant leaf",
    "bamboo leaf", "pineapple leaf", "rhubarb leaf", "pine needle",
    "orange blossom water", "rose water", "coconut water", "sea salt",
    "green tea", "black tea", "white tea", "black pepper", "pink pepper",
    "white pepper", "green pepper", "sichuan pepper", "white musk",
    "black musk", "deer musk", "white rose", "black rose", "pink rose",
    "blue rose", "white lily", "white lotus", "blue lotus", "white woods",
    "dry woods", "dark woods", "white leather", "white honey", "white truffle",
    "white cedar", "white thyme", "white orchid", "white peony", "red peony",
    "pink peony", "red apple", "green apple", "red currant", "black currant",
    "red ginger", "green cardamom", "black cardamom", "black locust",
    "green almond", "bitter almond", "roasted almond", "sour cherry",
    "green lemon", "key lime", "kaffir lime", "finger lime", "sea water",
    "rice powder", "sugar powder", "violet root", "carrot seed",
    "coriander seed", "angelica seed", "tonka bean", "cocoa bean",
    "coffee bean", "vanilla bean", "fir balsam", "fir resin", "lemon zest",
    "bergamot zest", "grapefruit zest", "peach skin", "blond tobacco",
    "salted caramel", "brown sugar", "cane sugar", "candied fruits",
    "dried fruits", "tropical fruits", "watery fruits", "exotic fruits",
    "red fruits", "black tea leaf", "earl grey tea", "mate tea",
}

TRADEMARK_RE = re.compile(r"[®™©]")
PAREN_RE = re.compile(r"\s*\([^)]*\)")
NONWORD_RE = re.compile(r"[^a-z0-9]+")


def clean(raw: str) -> str:
    """表記のブレを落とした比較用の文字列を返す。"""
    # NFKC より先に商標記号を落とす。NFKC は ™ を "TM" に展開してしまうため。
    s = TRADEMARK_RE.sub("", raw)
    s = unicodedata.normalize("NFKC", s)
    s = PAREN_RE.sub("", s)
    s = s.replace("’", "'").replace("–", "-").replace("—", "-")
    s = s.lower().strip()
    s = re.sub(r"\s+", " ", s)
    return s


def slugify(name: str) -> str:
    """URL と DB の自然キーに使えるスラグ。

    アクセント記号は落として ASCII に寄せる。
    そうしないと "fougère" が "foug-re" のような壊れたスラグになる。
    """
    s = clean(name)
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return NONWORD_RE.sub("-", s).strip("-")


def _strip_suffixes(s: str) -> str:
    changed = True
    while changed:
        changed = False
        for suf in FORM_SUFFIXES:
            if s.endswith(" " + suf) and s[: -(len(suf) + 1)].strip():
                s = s[: -(len(suf) + 1)].strip()
                changed = True
    return s


def _strip_origin(s: str) -> str:
    parts = s.split()
    while len(parts) > 1 and parts[0] in ORIGIN_QUALIFIERS:
        parts = parts[1:]
    while len(parts) > 1 and parts[0] in FORM_PREFIXES:
        parts = parts[1:]
    return " ".join(parts)


def canonical_form(raw: str) -> str:
    """修飾語を剥がした正規形を返す。

    保護リストに載っている語は剥がさない。
    剥がした結果が空になる場合は元の文字列を返す。
    """
    s = clean(raw)
    if not s:
        return s
    if s in PROTECTED:
        return s

    stripped = _strip_suffixes(s)
    if stripped in PROTECTED:
        return stripped
    stripped = _strip_origin(stripped)
    if stripped in PROTECTED:
        return stripped
    # 産地を剥がした後に抽出法が残る場合がある（例: "indian oud oil"）
    stripped = _strip_suffixes(stripped)

    return stripped or s


# 機械的な修飾語の除去では寄せられない別名。
# 学名・別称・綴りゆれを正規形へ手動で対応づける。
SYNONYM_OVERRIDES = {
    # --- 学名 → 一般名 ---
    "jasminum grandiflorum": "jasmine",
    "jasminum sambac": "jasmine sambac",
    "jasminum auriculatum": "jasmine",
    "rosa centifolia": "may rose",
    "rosa damascena": "damask rose",
    "iris pallida": "iris",
    "citrus aurantium": "bitter orange",
    "cananga odorata": "ylang-ylang",
    "boswellia": "frankincense",
    "commiphora": "myrrh",
    # --- 別称・綴りゆれ ---
    "olibanum": "frankincense",
    "incense": "frankincense",
    "styrax": "benzoin",
    "storax": "benzoin",
    "liquorice": "licorice",
    "absinth": "wormwood",
    "absinthe": "wormwood",
    "absinthe wormwood": "wormwood",
    "guaiac wood": "gaiac wood",
    "guaiacwood": "gaiac wood",
    "gaiacwood": "gaiac wood",
    "agarwood": "oud",
    "aoud": "oud",
    "oudh": "oud",
    "calone": "aquatic",
    "ozone": "ozonic",
    "ozonic": "ozonic",
    "aldehyde": "aldehydes",
    "orris": "iris",
    "orris root": "iris",
    "orris butter": "iris",
    "violet root": "iris",
    "mandarin": "mandarin orange",
    "tangerine": "mandarin orange",
    "clementine": "mandarin orange",
    "blackcurrant": "blackcurrant",
    "black currant": "blackcurrant",
    "cassis": "blackcurrant",
    "muguet": "lily of the valley",
    "lily-of-the-valley": "lily of the valley",
    "ylang ylang": "ylang-ylang",
    "cedar": "cedarwood",
    "cedar wood": "cedarwood",
    "sandal": "sandalwood",
    "santal": "sandalwood",
    "vanille": "vanilla",
    "tobacco leaf": "tobacco",
    "cacao": "cocoa",
    "coffee bean": "coffee",
    "cocoa bean": "cocoa",
    "vanilla bean": "vanilla",
    "vanilla orchid": "vanilla",
    "sea water": "seawater",
    "salt": "sea salt",
    "moss": "oakmoss",
    "mossy": "oakmoss",
    "tree moss": "treemoss",
    "labdanum resin": "labdanum",
    "amber xtreme": "amber",
    "ambroxan": "ambroxan",
    "ambrofix": "ambroxan",
    "ambreine": "amber",
    "petit grain": "petitgrain",
    "petitgrain": "petitgrain",
    "neroli oil": "neroli",
    "sichuan pepper": "sichuan pepper",
    "szechuan pepper": "sichuan pepper",
    "birch wood": "birch",
    "silver birch": "birch",
    "mahogany wood": "mahogany",
    "teakwood": "teak",
    "papyrus": "papyrus",
    "hedione": "hedione",
    "coumarin": "coumarin",
    # --- 総称ノート（分析上まとめる） ---
    "woody": "woody notes",
    "green": "green notes",
    "fresh": "fresh notes",
    "aromatic": "aromatic notes",
    "balsamic": "balsamic notes",
    "animalic": "animalic notes",
    "leathery": "leather",
    "metallic": "metallic notes",
    "powdery": "powdery notes",
    "creamy": "creamy notes",
    "sweet": "sweet notes",
    "mossy": "oakmoss",
    "marine": "aquatic",
    "aquatic notes": "aquatic",
    "watery notes": "aquatic",
    "solar note": "solar notes",
    # --- 追加バッチ ---
    "petigrain": "petitgrain",
    "iso-e-super": "iso e super",
    "isoesuper": "iso e super",
    "white cedarwood": "white cedar",
    "virginia cedar": "cedarwood",
    "texas cedar": "cedarwood",
    "lebanon cedar": "cedarwood",
    "atlas cedar": "cedarwood",
    "mysore sandalwood": "sandalwood",
    "java vetiver": "vetiver",
    "bourbon vetiver": "vetiver",
    "bourbon vanilla": "vanilla",
    "vanilla blossom": "vanilla",
    "bourbon geranium": "geranium",
    "provencal lavender": "lavender",
    "provençal lavender": "lavender",
    "true lavender": "lavender",
    "amalfi lemon": "lemon",
    "primofiore lemon": "lemon",
    "green mandarin orange": "mandarin orange",
    "red mandarin orange": "mandarin orange",
    "mandarin orange zest": "mandarin orange",
    "pink grapefruit": "grapefruit",
    "red grapefruit": "grapefruit",
    "orange zest": "orange",
    "red rose": "rose",
    "rosebud": "rose",
    "rose water": "rose",
    "white peach": "peach",
    "granny smith apple": "apple",
    "mirabelle plum": "plum",
    "woodland strawberry": "strawberry",
    "juniper berry": "juniper",
    "balsam fir": "fir balsam",
    "elemi resin": "elemi",
    "benzoin siam": "benzoin",
    "tolu balm": "tolu balsam",
    "copaiba balsam": "copaiba",
    "gurjum balsam": "gurjun balsam",
    "somalian frankincense": "frankincense",
    "aniseed": "anise",
    "ambrox": "ambroxan",
    "amberwood": "amber",
    "white amber": "amber",
    "black amber": "amber",
    "crystal amber": "amber",
    "cashmere": "cashmeran",
    "cashmere wood": "cashmeran",
    "artemisia": "wormwood",
    "vervain": "verbena",
    "lemon vervain": "verbena",
    "champaca flower": "champaca",
    "night-blooming jasmine": "jasmine",
    "water jasmine": "jasmine",
    "glycyrrhiza glabra": "licorice",
    "everlasting flower": "immortelle",
    "pot marigold": "marigold",
    "guatemala cardamom": "cardamom",
    "aged pepper": "pepper",
    "red pepper": "chili",
    "oak wood": "oak",
    "cinnamon leaf": "cinnamon",
    "blackcurrant leaf": "blackcurrant bud",
    "angelica root": "angelica",
}


def resolve(raw: str) -> str:
    """別名オーバーライドまで適用した最終的な正規形。"""
    form = canonical_form(raw)
    seen = set()
    while form in SYNONYM_OVERRIDES and form not in seen:
        seen.add(form)
        form = SYNONYM_OVERRIDES[form]
    return form
