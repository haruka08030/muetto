"""楽天ウェブサービス（楽天市場 商品検索 API）アダプタ。

国内 EC の価格・容量・購入リンク・JAN を取得する。
スクレイピングではなく公式 API を使う（ADR-006）。アフィリエイトとも接続できる。

    export RAKUTEN_APP_ID=xxxxxxxx
    python -m ingestion.sources.rakuten "ディオール ソヴァージュ"

ネットワークに触れるのは `search_items` だけ。
レスポンスの解釈は `parse_items` に分けてあり、こちらは通信なしでテストできる。
"""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.parse
import urllib.request
from dataclasses import dataclass

from ..config import USER_AGENT

ENDPOINT = "https://app.rakuten.co.jp/services/api/IchibaItem/Search/20220601"

# 「50ml」「50 mL」「50ミリ」などから容量を拾う。
VOLUME_RE = re.compile(r"(\d+(?:\.\d+)?)\s*(?:ml|mL|ML|ミリ)", re.IGNORECASE)


@dataclass
class Offer:
    """1 つの販売オファー。perfume_offers の 1 行に対応する。"""

    retailer_slug: str
    title: str
    url: str
    price: int
    currency: str = "JPY"
    volume_ml: float | None = None
    jan_code: str | None = None
    shop_name: str | None = None


def extract_volume_ml(title: str) -> float | None:
    match = VOLUME_RE.search(title or "")
    return float(match.group(1)) if match else None


def parse_items(payload: dict, *, retailer_slug: str = "rakuten") -> list[Offer]:
    """API レスポンスを Offer の一覧に変換する。

    レスポンスの形が変わってもここだけ直せば済むよう、
    取り出しはすべて get で行い、欠けている項目は落とす。
    """
    offers: list[Offer] = []
    for wrapper in payload.get("Items", []):
        item = wrapper.get("Item", wrapper)
        url = item.get("itemUrl")
        title = item.get("itemName")
        price = item.get("itemPrice")
        if not url or not title or not isinstance(price, int):
            continue
        offers.append(
            Offer(
                retailer_slug=retailer_slug,
                title=title,
                url=url,
                price=price,
                volume_ml=extract_volume_ml(title),
                jan_code=item.get("janCode") or None,
                shop_name=item.get("shopName") or None,
            )
        )
    return offers


def search_items(keyword: str, *, app_id: str | None = None, hits: int = 10) -> list[Offer]:
    """楽天市場を検索して Offer を返す。

    app_id が無ければ空を返す。認証情報が無い環境でも呼び出し側が壊れないようにする。
    """
    app_id = app_id or os.environ.get("RAKUTEN_APP_ID")
    if not app_id:
        print("RAKUTEN_APP_ID が未設定のため検索をスキップします", file=sys.stderr)
        return []

    params = urllib.parse.urlencode(
        {
            "applicationId": app_id,
            "keyword": keyword,
            "hits": max(1, min(hits, 30)),
            "sort": "+itemPrice",
            "format": "json",
        }
    )
    req = urllib.request.Request(
        f"{ENDPOINT}?{params}", headers={"User-Agent": USER_AGENT}
    )
    with urllib.request.urlopen(req, timeout=30) as res:
        return parse_items(json.load(res))


if __name__ == "__main__":
    for offer in search_items(" ".join(sys.argv[1:]) or "香水"):
        print(f"{offer.price:>8,}円  {offer.volume_ml or '?'}ml  {offer.title[:60]}")
