"""レコード表現と staging SQL 生成のテスト。"""

import pytest

from ingestion.records import PerfumeRecord, parse_concentration, parse_gender
from ingestion.stage import q, q_array
from ingestion.sources.rakuten import extract_volume_ml, parse_items


class TestParseConcentration:
    def test_英語表記(self):
        assert parse_concentration("Eau de Parfum") == "edp"
        assert parse_concentration("EDT") == "edt"
        assert parse_concentration("Extrait de Parfum") == "extrait"

    def test_日本語表記(self):
        assert parse_concentration("オードトワレ") == "edt"
        assert parse_concentration("オードパルファム") == "edp"

    def test_未知と欠損は_other(self):
        assert parse_concentration(None) == "other"
        assert parse_concentration("") == "other"
        assert parse_concentration("ボディミスト") == "other"


class TestParseGender:
    def test_対応表にあるもの(self):
        assert parse_gender("Women") == "feminine"
        assert parse_gender("メンズ") == "masculine"
        assert parse_gender("Unisex") == "unisex"

    def test_未知は_unknown(self):
        assert parse_gender(None) == "unknown"
        assert parse_gender("???") == "unknown"


class TestPerfumeRecord:
    def _record(self, **kwargs) -> PerfumeRecord:
        base = dict(
            brand_name_en="Fixture Maison",
            name_en="Rose Nocturne",
            source_name="test",
            top_notes=["Rose"],
        )
        base.update(kwargs)
        return PerfumeRecord(**base)

    def test_ノートが無いレコードは取り込まない(self):
        # ノートが無いと好み分析に寄与せず、検索結果を薄めるだけ
        assert not self._record(top_notes=[]).is_usable()
        assert self._record().is_usable()

    def test_ブランドか製品名が欠けたら取り込まない(self):
        assert not self._record(brand_name_en="").is_usable()
        assert not self._record(name_en="").is_usable()

    def test_内容が同じなら同じハッシュ(self):
        assert self._record().content_hash() == self._record().content_hash()

    def test_内容が変われば別のハッシュ(self):
        assert self._record().content_hash() != self._record(release_year=2020).content_hash()

    def test_香調の順序はハッシュに影響しない(self):
        a = self._record(accord_slugs=["floral", "woody"])
        b = self._record(accord_slugs=["woody", "floral"])
        assert a.content_hash() == b.content_hash()


class TestSqlQuoting:
    def test_アポストロフィを重ねて逃がす(self):
        assert q("L'Eau") == "'L''Eau'"

    def test_欠損は_null(self):
        assert q(None) == "null"
        assert q("") == "null"

    def test_配列の中のアポストロフィも逃がす(self):
        # 香料名には "bushman's candle" のようなものがある
        assert q_array(["bushman's candle"]) == """'{"bushman''s candle"}'"""

    def test_空配列(self):
        assert q_array([]) == "'{}'"

    def test_配列は除外語を落とす(self):
        assert q_array(["rose", "flibtix"]) == '\'{"rose"}\''


class TestRakuten:
    def test_タイトルから容量を拾う(self):
        assert extract_volume_ml("ディオール ソヴァージュ EDT 100ml") == 100.0
        assert extract_volume_ml("シャネル N°5 50 mL 正規品") == 50.0
        assert extract_volume_ml("香水 詰め替え") is None

    def test_レスポンスを_Offer_に変換する(self):
        payload = {
            "Items": [
                {
                    "Item": {
                        "itemName": "テスト香水 EDP 50ml",
                        "itemUrl": "https://item.rakuten.co.jp/shop/abc/",
                        "itemPrice": 12800,
                        "janCode": "4901234567890",
                        "shopName": "テストショップ",
                    }
                }
            ]
        }
        offers = parse_items(payload)
        assert len(offers) == 1
        assert offers[0].price == 12800
        assert offers[0].volume_ml == 50.0
        assert offers[0].jan_code == "4901234567890"

    def test_必須項目が欠けた要素は落とす(self):
        payload = {"Items": [{"Item": {"itemName": "名前だけ"}}]}
        assert parse_items(payload) == []

    def test_空のレスポンス(self):
        assert parse_items({}) == []
