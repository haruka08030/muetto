"""正規化ロジックの回帰テスト。

    cd tools/ingestion && python -m pytest tests/ -q
"""

from ingestion.blocklist import is_blocked
from ingestion.families import classify
from ingestion.normalize import canonical_form, resolve, slugify


class TestCanonicalForm:
    def test_産地の修飾語を落とす(self):
        assert canonical_form("Bulgarian rose") == "rose"
        assert canonical_form("Sicilian bergamot") == "bergamot"
        assert canonical_form("Madagascan vetiver") == "vetiver"

    def test_抽出法の修飾語を落とす(self):
        assert canonical_form("Turkish rose absolute") == "rose"
        assert canonical_form("Pink pepper CO2") == "pink pepper"
        assert canonical_form("Oakmoss absolute") == "oakmoss"

    def test_保護リストの語は分解しない(self):
        # "Orange blossom" から blossom を剥がすと柑橘の "orange" になってしまう
        assert canonical_form("Orange blossom") == "orange blossom"
        assert canonical_form("Orange blossom absolute") == "orange blossom"
        assert canonical_form("Black pepper") == "black pepper"
        assert canonical_form("Violet leaf") == "violet leaf"

    def test_商標記号を落とす(self):
        # NFKC より先に処理しないと ™ が "TM" に展開されてしまう
        assert canonical_form("Clearwood™") == "clearwood"

    def test_剥がしきって空にならない(self):
        assert canonical_form("Absolute") != ""


class TestResolve:
    def test_学名を一般名へ寄せる(self):
        assert resolve("Jasminum grandiflorum absolute") == "jasmine"
        assert resolve("Iris pallida") == "iris"

    def test_別称を寄せる(self):
        assert resolve("Agarwood") == "oud"
        assert resolve("Cassis") == "blackcurrant"
        assert resolve("Cedar") == "cedarwood"
        assert resolve("Orris butter") == "iris"

    def test_多段の別名を辿りきる(self):
        # orris root -> iris、途中で止まらないこと
        assert resolve("Orris root") == "iris"

    def test_循環しても止まる(self):
        assert resolve("Ozone") == "ozonic"


class TestSlugify:
    def test_アクセント記号を落とす(self):
        assert slugify("Fougère") == "fougere"
        assert slugify("Praliné") == "praline"

    def test_記号を区切りに変える(self):
        assert slugify("Ylang-Ylang") == "ylang-ylang"
        assert slugify("Lily of the valley") == "lily-of-the-valley"


class TestBlocklist:
    def test_一次ソースの造語を弾く(self):
        assert is_blocked("flibtix")
        assert is_blocked("zarquon")
        assert is_blocked("xylophazq")

    def test_香料名でない抽象名詞を弾く(self):
        assert is_blocked("disgust")
        assert is_blocked("stench")

    def test_実在する香料は弾かない(self):
        assert not is_blocked("rose")
        assert not is_blocked("oud")
        assert not is_blocked("oakmoss")
        # 前衛的な香水で実際に使われるものは残す
        assert not is_blocked("smoke")
        assert not is_blocked("leather")


class TestClassify:
    def test_明示辞書が優先される(self):
        assert classify("rose") == "floral"
        assert classify("jasmine") == "white_floral"
        assert classify("oud") == "woody"
        assert classify("tonka bean") == "gourmand"

    def test_キーワード規則で推定する(self):
        assert classify("some unknown wood") == "woody"
        assert classify("wild musk") == "musk"

    def test_判定できない語は_other(self):
        assert classify("zzzz") == "other"
