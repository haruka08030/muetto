"""パイプライン全体の設定値。"""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "data"
CACHE_DIR = ROOT / ".cache"

# --- 一次ソース ---------------------------------------------------------------
# Parfumo 由来のオープンデータセット（TidyTuesday 2024-12-10 経由で配布されているもの）。
# 香料語彙・香調語彙の初版を作るための素材として使う。
PARFUMO_CSV_URL = (
    "https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/"
    "data/2024/2024-12-10/parfumo_data_clean.csv"
)

USER_AGENT = "PerfumeAppIngestion/0.1 (+https://github.com/haruka08030/x-to-notion)"

# --- マスタ生成のしきい値 -----------------------------------------------------
# 正規化後の出現回数がこの値未満の香料はマスタに載せない。
# 少数の表記ゆれ・誤記が語彙を汚染するのを防ぐ。
MIN_NOTE_FREQUENCY = 20

# 香調アコードは固定リストとして扱い、ソース側の表現をここへ寄せる。
MIN_ACCORD_FREQUENCY = 100
