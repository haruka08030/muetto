"""香料マスタから除外する語。

一次ソース（Parfumo 由来のオープンデータ）には、実在しない香料名が
約 3.2% のレコードに 1 語ずつ混入している。無断再配布を検知するための
カナリア（透かし）と見られる。

    例: Flibtix / Zarquon / Snorplax / XylophazQ / Blimfark ...

これらは既知のカナリア語との共起率（lift）で統計的に洗い出したうえで、
人手でレビューして確定させた。手順は tools/ingestion/README.md を参照。

放置すると香料マスタに実在しない語が載り、好み分析の特徴量が汚染される。
さらに、透かしを含んだままのデータを配布することにもなる。
"""

from __future__ import annotations

# --- 実在しない造語（確実） ---------------------------------------------------
FABRICATED = {
    "flibtix", "zarquon", "snorplax", "vorplaxa", "grebzor", "nebulonix",
    "quintozar", "xylophazq", "moplonk", "drenzlor", "zenthorium", "blimfark",
    "trungle", "clorpt", "grimtak", "drindle", "zorplox", "bregnotrix",
    "glomtak", "vexlim", "glimzorith", "zarbot", "vorblex", "vorptal",
    "gorptik", "flabtus", "sneerlax", "finglebop", "quarklox", "plonktar",
    "lorenox", "sourmilk",
}

# --- 香料名ではない抽象名詞（確実） -------------------------------------------
# 「不快さ」「刺激臭」といった評価語であり、香料でも香調でもない。
ABSTRACT = {
    "disgust", "repulse", "offense", "nastiness", "noxiousness", "harshness",
    "pungency", "pungidity", "putridity", "rankness", "staleness", "malodor",
    "acridity", "spoilage", "contamination", "infestation", "filth", "grim",
    "funk", "grunge", "scum", "spoil", "rot", "decay", "stench", "foulness",
    "putrescence", "rancidness", "dankness", "odor", "spoiled", "must",
    "damp", "grease", "sludge", "nausea", "bilge", "smog", "pollution",
    "chemical", "acid", "rust", "harsh", "stink", "fume", "salty",
    "decomposing leaf", "smoky", "herbaceous", "powder", "musky", "gourmand",
    "oriental", "chypre", "solar", "spicy", "fruity", "floral", "citrus",
    "woods", "citrus fruits", "green leaves", "leaf green", "red berries",
    "precious woods", "blond woods", "white blossoms", "exotic fruits",
    "coniferous woods", "air",
}

# --- 香料として扱わない具体物（レビュー済み） ---------------------------------
# 実在の物質ではあるが、香水のノートとして記載される実態がなく、
# カナリア語との共起率が有意に高かったもの。
NON_NOTES = {
    "sewage", "sewer", "garbage", "manure", "carcass", "carrion",
    "spoiled meat", "spoiled spice", "rotten egg", "rotten onion",
    "rotting flower", "sour milk", "stalebread", "burnt toast",
    "burnt electronics", "melting plastic", "moldy wallpaper", "moldy leather",
    "mildew", "mold", "mothball", "skunk", "fish", "onion", "cabbage",
    "vinegar", "rancid oil", "rancid", "swamp", "sock", "gymwear", "vomit",
    "sulfur", "chlorine", "mud", "soil dust", "cigarette butt",
}

BLOCKED = FABRICATED | ABSTRACT | NON_NOTES

# --- 判断を保留した語 ---------------------------------------------------------
# 前衛的な香水では実際に使われる（CB I Hate Perfume、Comme des Garçons など）が、
# 出現数がカナリア語と同じ帯にあり、混入の可能性も残る。
# マスタには載せるが、レビュー対象として記録しておく。
SUSPECT_BUT_KEPT = {
    "smoke", "tar", "ash", "charcoal", "rubber", "asphalt", "diesel",
    "gasoline", "dust", "brine",
}


def is_blocked(canonical_name: str) -> bool:
    return canonical_name.lower().strip() in BLOCKED
