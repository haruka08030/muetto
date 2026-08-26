"""PerfumeRecord を staging_perfumes へ流し込む SQL を生成する。

DB へは直接つながない。生成した SQL を psql / Supabase CLI に流す運用にすることで、
接続情報をこのツールに持たせずに済ませる。
"""

from __future__ import annotations

import sys
import uuid
from pathlib import Path
from typing import Iterable

from .blocklist import is_blocked
from .normalize import clean
from .records import PerfumeRecord


def q(value: object) -> str:
    if value is None or value == "":
        return "null"
    return "'" + str(value).replace("'", "''") + "'"


def q_array(values: Iterable[str]) -> str:
    """text[] の SQL リテラルを作る。

    2 段のエスケープが要る。配列リテラル内では \\ と " をバックスラッシュで、
    それを包む SQL 文字列リテラルではシングルクォートを重ねて逃がす。
    香料名には "bushman's candle" のようにアポストロフィを含むものがある。
    """
    cleaned = [v for v in (clean(x) for x in values) if v and not is_blocked(v)]
    if not cleaned:
        return "'{}'"
    elements = []
    for v in cleaned:
        escaped = v.replace("\\", "\\\\").replace('"', '\\"')
        elements.append('"' + escaped + '"')
    literal = "{" + ", ".join(elements) + "}"
    return "'" + literal.replace("'", "''") + "'"


def write_batch_sql(
    records: list[PerfumeRecord],
    out_path: Path,
    *,
    source_name: str,
    batch_id: str | None = None,
) -> str:
    """staging への投入とマージまでを行う SQL を書き出す。

    バッチ ID は呼び出し側から渡せる。渡さなければ内容から決定的に導出し、
    同じ入力からは同じ SQL が生成されるようにする。
    """
    if batch_id is None:
        digest = "".join(sorted(r.content_hash() for r in records))[:4096]
        batch_id = str(uuid.uuid5(uuid.NAMESPACE_URL, source_name + digest))

    usable = [r for r in records if r.is_usable()]
    skipped = len(records) - len(usable)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as f:
        w = f.write
        w("-- tools/ingestion が生成したバッチ。直接編集しないこと。\n")
        w(f"-- ソース: {source_name}\n")
        w(f"-- 取り込み対象 {len(usable)} 件 / ノート無しで除外 {skipped} 件\n")
        w("--\n")
        w("-- staging に入れてからマージする。本番テーブルへ直接は書かない。\n")
        w("-- 未知ブランドの自動作成は既定で無効。有効にする場合は\n")
        w("-- merge_staging_batch の第 2 引数に true を渡す。\n\n")
        w("begin;\n\n")
        w("insert into ingestion_batches (id, source_name, staged_count)\n")
        w(f"values ({q(batch_id)}, {q(source_name)}, {len(usable)})\n")
        w("on conflict (id) do update set staged_count = excluded.staged_count;\n\n")
        w(f"delete from staging_perfumes where batch_id = {q(batch_id)};\n\n")

        if usable:
            w("insert into staging_perfumes (batch_id, source_name, source_url,\n")
            w("  content_hash, brand_name_en, brand_name_ja, brand_country,\n")
            w("  name_en, name_ja, concentration, gender_target, release_year,\n")
            w("  perfumer, image_url, top_notes, middle_notes, base_notes,\n")
            w("  accord_slugs) values\n")
            rows = []
            for r in usable:
                rows.append(
                    f"  ({q(batch_id)}, {q(r.source_name)}, {q(r.source_url)},\n"
                    f"   {q(r.content_hash())}, {q(r.brand_name_en)}, {q(r.brand_name_ja)},"
                    f" {q(r.brand_country)},\n"
                    f"   {q(r.name_en)}, {q(r.name_ja)}, {q(r.concentration)}::concentration,"
                    f" {q(r.gender_target)}::gender_target, {r.release_year or 'null'},\n"
                    f"   {q(r.perfumer)}, {q(r.image_url)}, {q_array(r.top_notes)},"
                    f" {q_array(r.middle_notes)}, {q_array(r.base_notes)},\n"
                    f"   {q_array(r.accord_slugs)})"
                )
            w(",\n".join(rows))
            w(";\n\n")

        w("commit;\n\n")
        w("-- マージは内容を確認してから実行する:\n")
        w(f"--   select * from merge_staging_batch({q(batch_id)});\n")

    print(f"生成: {out_path} ({out_path.stat().st_size:,} bytes)", file=sys.stderr)
    print(f"  取り込み {len(usable)} 件 / ノート無しで除外 {skipped} 件", file=sys.stderr)
    print(f"  batch_id = {batch_id}", file=sys.stderr)
    return batch_id
