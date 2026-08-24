#!/usr/bin/env python3
"""生成データとアプリのコードが食い違っていないか検査する。

    python scripts/check_consistency.py

香調カテゴリの色はアプリ側にハードコードしている（docs/screens.md 6 の方針）。
マスタ側に香調が増減したときに色の定義を更新し忘れると、
検索フィルタと分析グラフで色が食い違う。それを CI で検出する。
"""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ACCORDS_CSV = ROOT / "tools" / "ingestion" / "data" / "accords_master.csv"
NOTES_CSV = ROOT / "tools" / "ingestion" / "data" / "notes_master.csv"
ACCORD_COLORS = ROOT / "app" / "lib" / "src" / "theme" / "accord_colors.dart"
SEED_SQL = ROOT / "supabase" / "seed" / "0001_notes_accords.sql"

SLUG_RE = re.compile(r"^[a-z0-9-]+$")


def main() -> int:
    errors: list[str] = []

    accord_slugs = {r["slug"] for r in csv.DictReader(ACCORDS_CSV.open(encoding="utf-8"))}
    dart_slugs = set(re.findall(r"'([a-z0-9-]+)': Color", ACCORD_COLORS.read_text(encoding="utf-8")))

    for slug in sorted(accord_slugs - dart_slugs):
        errors.append(f"香調 '{slug}' に色が定義されていない: {ACCORD_COLORS.relative_to(ROOT)}")
    for slug in sorted(dart_slugs - accord_slugs):
        errors.append(f"香調 '{slug}' はマスタに存在しない: {ACCORD_COLORS.relative_to(ROOT)}")

    notes = list(csv.DictReader(NOTES_CSV.open(encoding="utf-8")))
    for row in notes:
        if not SLUG_RE.fullmatch(row["slug"]):
            errors.append(f"香料スラグの形式が不正: {row['slug']!r} ({row['name_en']})")

    slugs = [r["slug"] for r in notes]
    if len(slugs) != len(set(slugs)):
        dupes = {s for s in slugs if slugs.count(s) > 1}
        errors.append(f"香料スラグが重複している: {sorted(dupes)}")

    if not SEED_SQL.exists():
        errors.append(f"シードが生成されていない: {SEED_SQL.relative_to(ROOT)}")
    else:
        seed = SEED_SQL.read_text(encoding="utf-8")
        # 生成物が最新かどうかの粗いチェック。件数がずれていれば再生成が必要。
        if f"香料 {len(notes)} 件" not in seed:
            errors.append(
                "シードがマスタと同期していない。"
                "tools/ingestion で build_masters と emit_seed を流し直すこと"
            )

    if errors:
        for e in errors:
            print(f"✗ {e}", file=sys.stderr)
        return 1

    print(f"✓ 香調 {len(accord_slugs)} 件の色が一致")
    print(f"✓ 香料 {len(notes)} 件のスラグが正常")
    print("✓ シードはマスタと同期している")
    return 0


if __name__ == "__main__":
    sys.exit(main())
