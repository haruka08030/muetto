"""ローカル開発用の香水レコード生成。

検索や詳細画面を動かすには DB に香水レコードが必要だが、
一次データセットの香水レコードはリポジトリに入れない方針（ADR-012）。
そこで、キャッシュしたデータセットから **ローカル専用** の staging SQL を生成する。

    python -m ingestion.sources.dev_fixture --limit 2000

出力先は tools/ingestion/.local/ で、.gitignore で除外している。
本番のマスタは公式サイトと楽天/Amazon の公式 API から作る（ADR-006）。
これはあくまで開発中に画面を動かすための足場。
"""

from __future__ import annotations

import argparse
import collections
import csv
import sys
from pathlib import Path

from ..blocklist import is_blocked
from ..config import ROOT
from ..fetch import parfumo_csv
from ..normalize import clean, resolve
from ..records import PerfumeRecord, parse_concentration
from ..stage import write_batch_sql

OUT_DIR = ROOT / ".local"

# 開発用フィクスチャのバッチ ID。固定にして何度でも入れ直せるようにする。
# UUID は 16 進のみなので、それらしい語には寄せられない。
DEV_BATCH_ID = "d0000000-0000-4000-8000-000000000001"


def _split(value: str | None) -> list[str]:
    if not value or value == "NA":
        return []
    return [p.strip() for p in value.split(",") if p.strip() and p.strip() != "NA"]


def _notes(raw: str | None) -> list[str]:
    """正規形へ寄せ、除外語を落とす。マージ時の名寄せと同じ結果になる。"""
    out = []
    for item in _split(raw):
        canonical = resolve(item)
        if canonical and not is_blocked(canonical):
            out.append(canonical)
    return out


def build(limit: int, min_notes: int = 3) -> list[PerfumeRecord]:
    csv.field_size_limit(10**7)
    path = parfumo_csv()

    # ブランドごとの件数が偏らないよう、多いブランドから均等に拾う。
    by_brand: dict[str, list[PerfumeRecord]] = collections.defaultdict(list)

    with path.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            brand = (row.get("Brand") or "").strip()
            name = (row.get("Name") or "").strip()
            if not brand or not name or brand == "NA" or name == "NA":
                continue

            record = PerfumeRecord(
                brand_name_en=brand,
                name_en=name,
                source_name="dev-fixture",
                source_url=row.get("URL") or None,
                concentration=parse_concentration(row.get("Concentration")),
                release_year=(
                    int(row["Release_Year"])
                    if (row.get("Release_Year") or "NA").isdigit()
                    else None
                ),
                perfumer=(row.get("Perfumers") or "").split("/")[0].strip() or None,
                top_notes=_notes(row.get("Top_Notes")),
                middle_notes=_notes(row.get("Middle_Notes")),
                base_notes=_notes(row.get("Base_Notes")),
                accord_slugs=[
                    clean(a) for a in _split(row.get("Main_Accords"))
                    if clean(a) != "main accords"
                ],
            )
            if record.note_count() >= min_notes:
                by_brand[brand].append(record)

    # ブランドを件数順に並べ、各ブランドから順に 1 件ずつ取る。
    ordered = sorted(by_brand.values(), key=len, reverse=True)
    picked: list[PerfumeRecord] = []
    index = 0
    while len(picked) < limit and any(index < len(g) for g in ordered):
        for group in ordered:
            if index < len(group):
                picked.append(group[index])
                if len(picked) >= limit:
                    break
        index += 1
    return picked


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--limit", type=int, default=2000)
    parser.add_argument("--min-notes", type=int, default=3)
    args = parser.parse_args()

    records = build(args.limit, args.min_notes)
    brands = {r.brand_name_en for r in records}
    print(f"ブランド {len(brands)} / 香水 {len(records)}", file=sys.stderr)

    write_batch_sql(
        records,
        OUT_DIR / "dev_perfumes.sql",
        source_name="dev-fixture",
        batch_id=DEV_BATCH_ID,
    )
    print(
        "\n適用方法:\n"
        "  psql -f tools/ingestion/.local/dev_perfumes.sql\n"
        f"  psql -c \"select * from merge_staging_batch('{DEV_BATCH_ID}', true);\"",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
