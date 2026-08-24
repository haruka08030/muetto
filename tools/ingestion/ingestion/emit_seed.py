"""生成した香料・香調マスタから Supabase 用のシード SQL を出力する。

    python -m ingestion.emit_seed

出力: supabase/seed/0001_notes_accords.sql

slug を自然キーにした upsert として出力するので、何度流しても結果が変わらない。
再生成のたびに UUID が変わることもない。
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

from .config import DATA_DIR, ROOT

SEED_DIR = ROOT.parent.parent / "supabase" / "seed"
OUT = SEED_DIR / "0001_notes_accords.sql"


def q(value: str) -> str:
    """SQL のリテラルとしてクォートする。"""
    if value is None or value == "":
        return "null"
    return "'" + value.replace("'", "''") + "'"


def main() -> None:
    accords = list(csv.DictReader((DATA_DIR / "accords_master.csv").open(encoding="utf-8")))
    notes = list(csv.DictReader((DATA_DIR / "notes_master.csv").open(encoding="utf-8")))
    aliases = list(csv.DictReader((DATA_DIR / "note_aliases.csv").open(encoding="utf-8")))

    SEED_DIR.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8") as f:
        w = f.write
        w("-- 香調アコードマスタ・香料マスタのシード\n")
        w("--\n")
        w("-- このファイルは tools/ingestion が生成する。直接編集しないこと。\n")
        w("--   cd tools/ingestion && python -m ingestion.build_masters && python -m ingestion.emit_seed\n")
        w("--\n")
        w(f"-- 香調アコード {len(accords)} 件 / 香料 {len(notes)} 件 / 別名 {len(aliases)} 件\n")
        w("-- 出所と生成手順は docs/data-ingestion.md を参照。\n\n")

        w("insert into accords (slug, name_en, name_ja, sort_order) values\n")
        rows = [
            f"  ({q(a['slug'])}, {q(a['name_en'])}, {q(a['name_ja'])}, {i})"
            for i, a in enumerate(accords)
        ]
        w(",\n".join(rows))
        w("\non conflict (slug) do update set\n")
        w("  name_en = excluded.name_en,\n")
        w("  name_ja = excluded.name_ja,\n")
        w("  sort_order = excluded.sort_order;\n\n")

        w("insert into notes (slug, name_en, name_ja, family, needs_review) values\n")
        rows = [
            f"  ({q(n['slug'])}, {q(n['name_en'])}, {q(n['name_ja'])}, "
            f"{q(n['family'])}, {n['needs_review']})"
            for n in notes
        ]
        w(",\n".join(rows))
        w("\non conflict (slug) do update set\n")
        w("  name_en = excluded.name_en,\n")
        w("  name_ja = excluded.name_ja,\n")
        w("  family = excluded.family,\n")
        w("  needs_review = excluded.needs_review;\n\n")

        w("insert into note_aliases (alias, note_id)\n")
        w("select v.alias, n.id from (values\n")
        rows = [
            f"  ({q(a['alias'])}, {q(a['canonical_slug'])})"
            for a in aliases
        ]
        w(",\n".join(rows))
        w("\n) as v (alias, note_slug)\n")
        w("join notes n on n.slug = v.note_slug\n")
        w("on conflict (alias) do update set note_id = excluded.note_id;\n")

    size = OUT.stat().st_size
    print(f"生成: {OUT} ({size:,} bytes)", file=sys.stderr)
    print(f"  香調 {len(accords)} / 香料 {len(notes)} / 別名 {len(aliases)}", file=sys.stderr)


if __name__ == "__main__":
    main()
