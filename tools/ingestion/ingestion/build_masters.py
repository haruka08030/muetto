"""香料マスタ・香調アコードマスタを生成する。

    python -m ingestion.build_masters

出力（tools/ingestion/data/ 配下、生成物だがリポジトリにコミットする）:

    notes_master.csv    香料マスタ（正規形・系統・日本語名・出現回数）
    note_aliases.csv    別名 → 正規形の対応表（検索と取り込みの名寄せに使う）
    accords_master.csv  香調アコードの固定リスト
    unmapped_notes.csv  しきい値未満で採用しなかった語（人手レビュー用）
"""

from __future__ import annotations

import collections
import csv
import sys

from .blocklist import SUSPECT_BUT_KEPT, is_blocked
from .config import DATA_DIR, MIN_ACCORD_FREQUENCY, MIN_NOTE_FREQUENCY
from .families import FAMILY_LABELS_JA, classify
from .fetch import parfumo_csv
from .ja_names import ACCORD_NAMES_JA, NOTE_NAMES_JA
from .normalize import SYNONYM_OVERRIDES, clean, resolve, slugify

NOTE_COLUMNS = ("Top_Notes", "Middle_Notes", "Base_Notes")


def _split(value: str | None) -> list[str]:
    if not value or value == "NA":
        return []
    return [p.strip() for p in value.split(",") if p.strip() and p.strip() != "NA"]


def collect() -> tuple[collections.Counter, dict[str, collections.Counter], collections.Counter]:
    """一次ソースを走査して、正規形の出現回数と別名の対応を集める。"""
    csv.field_size_limit(10**7)
    path = parfumo_csv()

    note_freq: collections.Counter[str] = collections.Counter()
    # 正規形 -> {元の表記: 出現回数}
    aliases: dict[str, collections.Counter[str]] = collections.defaultdict(collections.Counter)
    accord_freq: collections.Counter[str] = collections.Counter()

    with path.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            for column in NOTE_COLUMNS:
                for raw in _split(row.get(column)):
                    canonical = resolve(raw)
                    if not canonical or is_blocked(canonical):
                        continue
                    note_freq[canonical] += 1
                    if clean(raw) != canonical:
                        aliases[canonical][clean(raw)] += 1
            for raw in _split(row.get("Main_Accords")):
                accord_freq[clean(raw)] += 1

    return note_freq, aliases, accord_freq


def write_notes(note_freq, aliases) -> int:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    adopted = [(n, f) for n, f in note_freq.most_common() if f >= MIN_NOTE_FREQUENCY]

    with (DATA_DIR / "notes_master.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["slug", "name_en", "name_ja", "family", "family_ja", "frequency", "alias_count", "needs_review"])
        for name, freq in adopted:
            family = classify(name)
            w.writerow([
                slugify(name),
                name,
                NOTE_NAMES_JA.get(name, ""),
                family,
                FAMILY_LABELS_JA[family],
                freq,
                len(aliases.get(name, {})),
                "true" if name in SUSPECT_BUT_KEPT else "false",
            ])

    # 手動で定義した別名も書き出す。
    # 一次データに出現しなかったものは aliases に入らないが、
    # DB 側の resolve_note_id はこの表しか見ないため、載せておかないと解決できない。
    adopted_set = {n for n, _ in adopted}
    manual: dict[str, str] = {}
    for alias in SYNONYM_OVERRIDES:
        canonical = resolve(alias)
        if canonical in adopted_set and alias != canonical:
            manual[alias] = canonical

    # set をそのまま回すと実行ごとに順序が変わり、生成物に差分が出る。
    # 生成物はコミットするため、必ず決定的な順序で書き出す。
    with (DATA_DIR / "note_aliases.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["alias", "canonical_slug", "canonical_name_en", "frequency"])
        emitted = set()
        for name in sorted(adopted_set):
            for alias, freq in sorted(aliases.get(name, {}).items(), key=lambda kv: -kv[1]):
                w.writerow([alias, slugify(name), name, freq])
                emitted.add(alias)
        for alias, canonical in sorted(manual.items()):
            if alias not in emitted:
                w.writerow([alias, slugify(canonical), canonical, 0])

    with (DATA_DIR / "unmapped_notes.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["name_en", "frequency", "suggested_family"])
        for name, freq in note_freq.most_common():
            if freq < MIN_NOTE_FREQUENCY:
                w.writerow([name, freq, classify(name)])

    return len(adopted)


def write_accords(accord_freq) -> int:
    rows = []
    for name, freq in accord_freq.most_common():
        if freq < MIN_ACCORD_FREQUENCY or name == "main accords":
            continue
        slug = slugify(name)
        rows.append([slug, name.title(), ACCORD_NAMES_JA.get(slug, ""), freq])

    with (DATA_DIR / "accords_master.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["slug", "name_en", "name_ja", "frequency"])
        w.writerows(rows)
    return len(rows)


def main() -> None:
    note_freq, aliases, accord_freq = collect()
    n_notes = write_notes(note_freq, aliases)
    n_accords = write_accords(accord_freq)

    total = sum(note_freq.values())
    covered = sum(f for n, f in note_freq.items() if f >= MIN_NOTE_FREQUENCY)
    missing_ja = sum(
        1 for n, f in note_freq.items()
        if f >= MIN_NOTE_FREQUENCY and n not in NOTE_NAMES_JA
    )

    print(f"香料マスタ      : {n_notes} 件（正規化前のユニーク数 {len(note_freq)}）", file=sys.stderr)
    print(f"出現カバー率    : {covered / total:.2%}", file=sys.stderr)
    print(f"日本語名 未設定 : {missing_ja} 件", file=sys.stderr)
    print(f"香調アコード    : {n_accords} 件", file=sys.stderr)
    print(f"出力先          : {DATA_DIR}", file=sys.stderr)


if __name__ == "__main__":
    main()
