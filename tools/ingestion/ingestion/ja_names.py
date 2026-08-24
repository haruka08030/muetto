"""香料の日本語名辞書。

一次ソースは英語表記しか持たないため、日本語名は人手で対応づける。
未収録の香料は `name_ja` を NULL のままにし、アプリ側は英語名にフォールバックする
（[docs/data-model.md] のロケール解決関数を参照）。

新しい香料の日本語名はここに追記していく。
"""

from __future__ import annotations

NOTE_NAMES_JA: dict[str, str] = {
    # --- シトラス ---
    "bergamot": "ベルガモット", "lemon": "レモン", "lime": "ライム",
    "orange": "オレンジ", "bitter orange": "ビターオレンジ",
    "blood orange": "ブラッドオレンジ", "mandarin orange": "マンダリンオレンジ",
    "grapefruit": "グレープフルーツ", "yuzu": "柚子", "citron": "シトロン",
    "kumquat": "金柑", "pomelo": "ポメロ", "petitgrain": "プチグレン",
    "neroli": "ネロリ", "lemon verbena": "レモンバーベナ",
    "lemon grass": "レモングラス", "kaffir lime": "カフィアライム",
    "key lime": "キーライム", "lemon zest": "レモンの皮",
    "bergamot zest": "ベルガモットの皮", "grapefruit zest": "グレープフルーツの皮",
    "orange leaf": "オレンジリーフ", "citruses": "柑橘", "citrus notes": "シトラスノート",

    # --- フローラル ---
    "rose": "ローズ", "may rose": "メイローズ", "damask rose": "ダマスクローズ",
    "iris": "イリス", "violet": "バイオレット", "peony": "ピオニー",
    "geranium": "ゼラニウム", "lavender": "ラベンダー", "carnation": "カーネーション",
    "mimosa": "ミモザ", "heliotrope": "ヘリオトロープ", "hyacinth": "ヒヤシンス",
    "narcissus": "ナルシス", "chamomile": "カモミール", "poppy": "ポピー",
    "lotus": "ロータス", "waterlily": "スイレン", "cyclamen": "シクラメン",
    "hibiscus": "ハイビスカス", "camellia": "椿", "marigold": "マリーゴールド",
    "clover": "クローバー", "tulip": "チューリップ", "immortelle": "イモーテル",
    "cherry blossom": "桜", "apple blossom": "林檎の花", "peach blossom": "桃の花",
    "almond blossom": "アーモンドの花", "plum blossom": "梅の花",
    "sunflower": "ひまわり", "rose hip": "ローズヒップ", "flowers": "花",
    "floral notes": "フローラルノート", "wild flowers": "野の花",
    "blossoms": "花々", "parma violet": "パルマスミレ", "datura": "ダチュラ",

    # --- ホワイトフローラル ---
    "jasmine": "ジャスミン", "jasmine sambac": "サンバックジャスミン",
    "tuberose": "チュベローズ", "gardenia": "ガーデニア",
    "ylang-ylang": "イランイラン", "orange blossom": "オレンジブロッサム",
    "magnolia": "マグノリア", "freesia": "フリージア",
    "lily of the valley": "スズラン", "lily": "リリー", "white lily": "白百合",
    "orchid": "オーキッド", "white orchid": "ホワイトオーキッド",
    "frangipani": "プルメリア", "champaca": "チャンパカ",
    "stephanotis": "ステファノティス", "honeysuckle": "スイカズラ",
    "linden": "リンデン", "linden blossom": "リンデンブロッサム",
    "white lotus": "白蓮", "acacia": "アカシア", "star jasmine": "テイカカズラ",
    "ginger flower": "ジンジャーフラワー", "white flowers": "白い花",

    # --- グリーン ---
    "green notes": "グリーンノート", "grass": "草", "galbanum": "ガルバナム",
    "violet leaf": "バイオレットリーフ", "ivy": "アイビー", "bamboo": "竹",
    "fig leaf": "フィグリーフ", "tomato leaf": "トマトリーフ", "leaves": "葉",
    "fern": "シダ", "cucumber": "キュウリ", "shiso": "紫蘇",
    "shiso leaf": "紫蘇の葉", "blackcurrant bud": "カシスの芽",
    "hay": "干し草", "cotton": "コットン", "seagrass": "海藻",

    # --- ハーバル / アロマティック ---
    "mint": "ミント", "spearmint": "スペアミント", "peppermint": "ペパーミント",
    "basil": "バジル", "thyme": "タイム", "rosemary": "ローズマリー",
    "sage": "セージ", "clary sage": "クラリセージ", "tarragon": "タラゴン",
    "oregano": "オレガノ", "wormwood": "ニガヨモギ", "mugwort": "ヨモギ",
    "angelica": "アンジェリカ", "hyssop": "ヒソップ", "verbena": "バーベナ",
    "eucalyptus": "ユーカリ", "camphor": "カンファー", "myrtle": "ミルテ",
    "laurel": "ローレル", "bay leaf": "ローリエ", "herbs": "ハーブ",
    "aromatic notes": "アロマティックノート", "coumarin": "クマリン",
    "turmeric": "ターメリック", "celery": "セロリ", "calamus": "菖蒲",

    # --- フルーティ ---
    "apple": "林檎", "red apple": "赤林檎", "green apple": "青林檎",
    "pear": "洋梨", "nashi pear": "梨", "peach": "桃", "apricot": "アプリコット",
    "plum": "プラム", "prune": "プルーン", "cherry": "チェリー",
    "sour cherry": "サワーチェリー", "raspberry": "ラズベリー",
    "strawberry": "苺", "blackberry": "ブラックベリー",
    "blueberry": "ブルーベリー", "cranberry": "クランベリー",
    "blackcurrant": "カシス", "red currant": "赤スグリ", "currant": "スグリ",
    "berries": "ベリー", "fruits": "果実", "red fruits": "赤い果実",
    "candied fruits": "砂糖漬けの果実", "dried fruits": "ドライフルーツ",
    "tropical fruits": "トロピカルフルーツ", "melon": "メロン",
    "watermelon": "スイカ", "pineapple": "パイナップル", "mango": "マンゴー",
    "papaya": "パパイヤ", "guava": "グアバ", "passionfruit": "パッションフルーツ",
    "lychee": "ライチ", "banana": "バナナ", "coconut": "ココナッツ",
    "coconut milk": "ココナッツミルク", "fig": "イチジク", "date": "デーツ",
    "grape": "葡萄", "kiwi": "キウイ", "quince": "マルメロ",
    "rhubarb": "ルバーブ", "pomegranate": "ザクロ", "nectarine": "ネクタリン",
    "peach skin": "桃の産毛", "tamarind": "タマリンド",

    # --- ウッディ ---
    "woody notes": "ウッディノート", "sandalwood": "サンダルウッド",
    "cedarwood": "シダーウッド", "oud": "ウード", "vetiver": "ベチバー",
    "patchouli": "パチュリ", "gaiac wood": "ガイアックウッド",
    "rosewood": "ローズウッド", "birch": "バーチ", "teak": "チーク",
    "mahogany": "マホガニー", "ebony": "黒檀", "cypress": "サイプレス",
    "juniper": "ジュニパー", "pine": "パイン", "pine needle": "松葉",
    "spruce": "スプルース", "fir": "モミ", "sequoia": "セコイア",
    "driftwood": "流木", "white woods": "ホワイトウッド",
    "dry woods": "ドライウッド", "dark woods": "ダークウッド",
    "amyris": "アミリス", "papyrus": "パピルス", "nagarmotha": "ナガルモタ",
    "cashmeran": "カシュメラン", "bark": "樹皮", "chestnut": "栗",

    # --- スパイシー ---
    "pepper": "ペッパー", "black pepper": "ブラックペッパー",
    "pink pepper": "ピンクペッパー", "white pepper": "ホワイトペッパー",
    "sichuan pepper": "花椒", "cardamom": "カルダモン",
    "green cardamom": "グリーンカルダモン", "cinnamon": "シナモン",
    "cassia": "カッシア", "clove": "クローブ", "nutmeg": "ナツメグ",
    "mace": "メース", "ginger": "ジンジャー", "saffron": "サフラン",
    "coriander": "コリアンダー", "cumin": "クミン", "caraway": "キャラウェイ",
    "anise": "アニス", "star anise": "八角", "fennel": "フェンネル",
    "pimento": "ピメント", "allspice": "オールスパイス", "spices": "スパイス",
    "spicy notes": "スパイシーノート", "carrot seed": "キャロットシード",
    "elemi": "エレミ",

    # --- グルマン ---
    "vanilla": "バニラ", "chocolate": "チョコレート",
    "dark chocolate": "ダークチョコレート", "cocoa": "カカオ",
    "coffee": "コーヒー", "caramel": "キャラメル",
    "salted caramel": "塩キャラメル", "honey": "蜂蜜", "sugar": "砂糖",
    "brown sugar": "黒糖", "cane sugar": "サトウキビ", "almond": "アーモンド",
    "bitter almond": "ビターアーモンド", "hazelnut": "ヘーゼルナッツ",
    "pistachio": "ピスタチオ", "walnut": "胡桃", "nuts": "ナッツ",
    "praline": "プラリネ", "marshmallow": "マシュマロ", "milk": "ミルク",
    "cream": "クリーム", "creamy notes": "クリーミーノート", "butter": "バター",
    "toffee": "トフィー", "nougat": "ヌガー", "rice": "米", "bread": "パン",
    "biscuit": "ビスケット", "popcorn": "ポップコーン", "maple": "メープル",
    "licorice": "リコリス", "tonka bean": "トンカビーン", "truffle": "トリュフ",
    "dulce de leche": "ドゥルセ・デ・レチェ", "vanilla cream": "バニラクリーム",

    # --- バルサミック ---
    "balsamic notes": "バルサミックノート", "amber": "アンバー",
    "benzoin": "ベンゾイン", "labdanum": "ラブダナム",
    "frankincense": "フランキンセンス", "myrrh": "ミルラ",
    "opoponax": "オポポナックス", "resins": "樹脂", "balsam": "バルサム",
    "fir balsam": "モミの樹脂", "peru balsam": "ペルーバルサム",
    "tolu balsam": "トルーバルサム", "mastic": "マスティック",
    "beeswax": "蜜蝋", "copaiba": "コパイバ",

    # --- アニマリック / ムスク ---
    "animalic notes": "アニマリックノート", "civet": "シベット",
    "castoreum": "カストリウム", "ambergris": "アンバーグリス",
    "hyraceum": "ハイラシウム", "costus": "コスタス", "musk": "ムスク",
    "white musk": "ホワイトムスク", "ambrette": "アンブレット",
    "deer musk": "麝香", "skin": "肌の香り",

    # --- アクアティック ---
    "aquatic": "アクアティック", "sea salt": "海塩", "seawater": "海水",
    "sea notes": "マリンノート", "ozonic": "オゾンノート",
    "water notes": "ウォーターノート", "rain accord": "雨のアコード",
    "algae": "藻", "seaweed": "海藻",

    # --- パウダリー / アーシー ---
    "powdery notes": "パウダリーノート", "talcum": "タルカムパウダー",
    "rice powder": "米粉", "earthy notes": "アーシーノート", "soil": "土",
    "mushroom": "きのこ", "lichen": "地衣類", "oakmoss": "オークモス",
    "treemoss": "ツリーモス",

    # --- レザー / タバコ ---
    "leather": "レザー", "suede": "スエード", "birch tar": "バーチタール",
    "tobacco": "タバコ", "blond tobacco": "ブロンドタバコ", "smoke": "煙",

    # --- アルコーリック ---
    "rum": "ラム", "whisky": "ウイスキー", "cognac": "コニャック",
    "brandy": "ブランデー", "gin": "ジン", "vodka": "ウォッカ",
    "champagne": "シャンパン", "wine": "ワイン", "amaretto": "アマレット",

    # --- その他 ---
    "aldehydes": "アルデヒド", "metallic notes": "メタリックノート",
    "mineral notes": "ミネラルノート", "ambroxan": "アンブロキサン",
    "hedione": "ヘディオン", "iso e super": "イソイースーパー",
    "tea": "紅茶", "green tea": "緑茶", "black tea": "紅茶",
    "white tea": "白茶", "matcha": "抹茶", "mate": "マテ茶",
    "fresh notes": "フレッシュノート", "sweet notes": "スイートノート",
    "solar notes": "ソーラーノート", "ice accord": "アイスアコード",
}

# 香調アコード（固定リスト）の日本語名。
ACCORD_NAMES_JA: dict[str, str] = {
    "floral": "フローラル", "spicy": "スパイシー", "sweet": "スイート",
    "woody": "ウッディ", "fresh": "フレッシュ", "fruity": "フルーティ",
    "citrus": "シトラス", "green": "グリーン", "powdery": "パウダリー",
    "synthetic": "シンセティック", "oriental": "オリエンタル",
    "creamy": "クリーミー", "gourmand": "グルマン", "resinous": "レジナス",
    "aquatic": "アクアティック", "smoky": "スモーキー", "leathery": "レザリー",
    "earthy": "アーシー", "animal": "アニマリック", "chypre": "シプレ",
    "fougere": "フゼア",
}


# 追加バッチ。build_masters の「日本語名 未設定」出力を見て順次埋めていく。
NOTE_NAMES_JA.update({
    "osmanthus": "金木犀", "cistus": "シスタス", "lilac": "ライラック",
    "praliné": "プラリネ", "passion fruit": "パッションフルーツ",
    "davana": "ダバナ", "ambrette seed": "アンブレットシード",
    "tiaré": "ティアレ", "tagetes": "マリーゴールド", "verbena": "バーベナ",
    "cypriol": "サイプリオール", "water lily": "スイレン",
    "hawthorn": "サンザシ", "cedar leaf": "シダーリーフ",
    "gurjun balsam": "ガジュツバルサム", "oak": "オーク",
    "coconut water": "ココナッツウォーター", "white peony": "白牡丹",
    "broom": "エニシダ", "pink peony": "ピンクピオニー",
    "coriander seed": "コリアンダーシード", "wisteria": "藤",
    "honey pomelo": "文旦", "cotton candy": "綿菓子",
    "sweet pea": "スイートピー", "sea breeze": "潮風",
    "champaca": "チャンパカ", "passion flower": "パッションフラワー",
    "akigalawood": "アキガラウッド", "birch leaf": "バーチリーフ",
    "lemon blossom": "レモンの花", "marjoram": "マジョラム",
    "tobacco flower": "タバコの花", "chili": "チリ",
    "fermented almond": "発酵アーモンド", "iso e super": "イソイースーパー",
    "litsea cubeba": "リッツェアクベバ", "starfruit": "スターフルーツ",
    "stone pine": "イタリアカサマツ", "vermouth": "ベルモット",
    "black leather": "ブラックレザー", "carrot": "人参",
    "cannabis": "カンナビス", "pear blossom": "洋梨の花",
    "lemon leaf": "レモンリーフ", "jasmine tea": "ジャスミンティー",
    "blue lotus": "青蓮", "sand": "砂", "green pepper": "グリーンペッパー",
    "palo santo": "パロサント", "orcanox": "オルカノックス",
    "white chocolate": "ホワイトチョコレート", "white freesia": "白フリージア",
    "kelp": "昆布", "geranium leaf": "ゼラニウムリーフ",
    "black orchid": "ブラックオーキッド", "white cedar": "ホワイトシダー",
    "white rose": "白薔薇", "elemi": "エレミ", "juniper": "ジュニパー",
    "copaiba": "コパイバ", "tolu balsam": "トルーバルサム",
    "cashmeran": "カシュメラン", "ambroxan": "アンブロキサン",
    "anise": "アニス", "wormwood": "ニガヨモギ", "immortelle": "イモーテル",
    "marigold": "マリーゴールド", "licorice": "リコリス",
    "angelica": "アンジェリカ", "blackcurrant bud": "カシスの芽",
    "smoke": "煙", "tar": "タール", "ash": "灰", "charcoal": "炭",
    "rubber": "ゴム", "asphalt": "アスファルト", "diesel": "ディーゼル",
    "gasoline": "ガソリン", "dust": "埃", "brine": "潮",
})
