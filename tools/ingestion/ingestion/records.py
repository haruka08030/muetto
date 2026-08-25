"""香水レコードを staging へ投入するための中間表現。

ソースごとのアダプタはこの `PerfumeRecord` を返す。
アダプタを差し替えても下流（staging 投入・マージ）が変わらないようにするため、
ソース固有の形はここで吸収しきる。
"""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass, field

# 賦香率の表記ゆれ → DB の enum 値。
CONCENTRATION_MAP = {
    "eau de cologne": "edc", "cologne": "edc", "edc": "edc",
    "オーデコロン": "edc",
    "eau de toilette": "edt", "edt": "edt", "オードトワレ": "edt",
    "eau de parfum": "edp", "edp": "edp", "オードパルファム": "edp",
    "オードパルファン": "edp",
    "parfum": "parfum", "perfume": "parfum", "パルファム": "parfum",
    "extrait de parfum": "extrait", "extrait": "extrait",
    "エクストレ": "extrait", "エクストレ・ド・パルファム": "extrait",
    "parfum de toilette": "edp",
}

GENDER_MAP = {
    "women": "feminine", "female": "feminine", "feminine": "feminine",
    "for women": "feminine", "レディース": "feminine", "女性": "feminine",
    "men": "masculine", "male": "masculine", "masculine": "masculine",
    "for men": "masculine", "メンズ": "masculine", "男性": "masculine",
    "unisex": "unisex", "shared": "unisex", "ユニセックス": "unisex",
}


def parse_concentration(raw: str | None) -> str:
    if not raw:
        return "other"
    return CONCENTRATION_MAP.get(raw.strip().lower(), "other")


def parse_gender(raw: str | None) -> str:
    if not raw:
        return "unknown"
    return GENDER_MAP.get(raw.strip().lower(), "unknown")


@dataclass
class PerfumeRecord:
    """1 つの香水製品。staging_perfumes の 1 行に対応する。"""

    brand_name_en: str
    name_en: str
    source_name: str

    brand_name_ja: str | None = None
    brand_country: str | None = None
    name_ja: str | None = None
    concentration: str = "other"
    gender_target: str = "unknown"
    release_year: int | None = None
    perfumer: str | None = None
    image_url: str | None = None
    source_url: str | None = None

    top_notes: list[str] = field(default_factory=list)
    middle_notes: list[str] = field(default_factory=list)
    base_notes: list[str] = field(default_factory=list)
    accord_slugs: list[str] = field(default_factory=list)

    def note_count(self) -> int:
        return len(self.top_notes) + len(self.middle_notes) + len(self.base_notes)

    def content_hash(self) -> str:
        """再取得時の差分検知に使う。内容が変わらなければ同じ値になる。"""
        payload = json.dumps(
            {
                "brand": self.brand_name_en,
                "name": self.name_en,
                "concentration": self.concentration,
                "gender": self.gender_target,
                "year": self.release_year,
                "perfumer": self.perfumer,
                "top": self.top_notes,
                "middle": self.middle_notes,
                "base": self.base_notes,
                "accords": sorted(self.accord_slugs),
            },
            ensure_ascii=False,
            sort_keys=True,
        )
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()

    def is_usable(self) -> bool:
        """マスタに載せる価値があるか。

        ノートが 1 つも無いレコードは好み分析に寄与せず、
        検索結果を薄めるだけなので取り込まない
        （docs/data-ingestion.md 1「母数より充足率を優先する」）。
        """
        return bool(self.brand_name_en and self.name_en and self.note_count() > 0)
