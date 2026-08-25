"""一次ソースの取得。

取得したファイルは `.cache/` に保存し、再実行時は再ダウンロードしない。
ネットワークへのアクセスはこのモジュールに閉じ込める。
"""

from __future__ import annotations

import sys
import urllib.request
from pathlib import Path

from .config import CACHE_DIR, PARFUMO_CSV_URL, USER_AGENT


def download(url: str, dest: Path, *, force: bool = False) -> Path:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists() and not force:
        print(f"cached: {dest} ({dest.stat().st_size:,} bytes)", file=sys.stderr)
        return dest

    print(f"downloading: {url}", file=sys.stderr)
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=300) as res, dest.open("wb") as f:
        f.write(res.read())
    print(f"saved: {dest} ({dest.stat().st_size:,} bytes)", file=sys.stderr)
    return dest


def parfumo_csv(*, force: bool = False) -> Path:
    return download(PARFUMO_CSV_URL, CACHE_DIR / "parfumo_data_clean.csv", force=force)


if __name__ == "__main__":
    parfumo_csv(force="--force" in sys.argv)
