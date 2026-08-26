# Muetto

試香の記憶をデジタル化し、蓄積した評価から「自分の好きな香料・苦手な香料」を客観化して、
次の1本の失敗を防ぐパーソナル香水管理アプリ。

> ワインにおける Vivino のポジションを、香水で実現することを目指す。

名前は試香紙（ムエット）に由来する。店頭で受け取っても捨ててしまう
あの紙の記憶を、デジタルに残すのがこのアプリの出発点。

## ステータス

**Phase 1（香水 DB と検索）まで実装済み**。認証・DB スキーマ・香料マスタ・
取り込みパイプライン・香水検索・香水詳細まで。
残るのは本番データの投入（公式サイトと EC の公式 API の資格情報が要る）。
試香ログ・好み分析は Phase 2 以降（[docs/roadmap.md](docs/roadmap.md)）。

## ドキュメント

| ドキュメント | 内容 |
|---|---|
| [docs/requirements.md](docs/requirements.md) | 要件定義書（コア。機能要件・非機能要件・スコープ） |
| [docs/screens.md](docs/screens.md) | 画面一覧と主要導線 |
| [docs/data-model.md](docs/data-model.md) | データモデル・DBスキーマ・RLS方針 |
| [docs/preference-algorithm.md](docs/preference-algorithm.md) | 好み分析・レコメンドのアルゴリズム仕様 |
| [docs/data-ingestion.md](docs/data-ingestion.md) | 香水マスタDBの構築・運用方針 |
| [docs/roadmap.md](docs/roadmap.md) | 開発フェーズとマイルストーン |
| [docs/decisions.md](docs/decisions.md) | 意思決定ログ（ADR） |

## 技術スタック

- **モバイル**: Flutter（iOS / Android）+ Riverpod + go_router
- **バックエンド**: Supabase（PostgreSQL / Auth / Storage / Edge Functions）
- **OCR**: Google ML Kit（オンデバイス・テキスト認識）— Phase 4
- **取り込み**: Python（外部依存なし）

## ディレクトリ構成

```
app/                 Flutter アプリ
supabase/
  migrations/        DB スキーマ
  seed/              香料・香調マスタのシード（生成物）
  tests/             RLS ポリシーの検証
tools/ingestion/     香水マスタの取り込み・正規化パイプライン
scripts/             検証スクリプト
docs/                要件定義・設計
```

## セットアップ

```bash
git clone https://github.com/haruka08030/x-to-notion.git
cd x-to-notion
./scripts/setup.sh
```

必要なツールを確認し、Flutter のプラットフォーム雛形（`app/ios`, `app/android`）を
生成して依存を取得する。冪等なので何度実行してもよい。

`app/ios` と `app/android` はリポジトリに含めていない。
Bundle ID がプロダクト名に依存するため、名前が確定するまで固定したくないから。
確定したら次のように生成し直す。

```bash
rm -rf app/ios app/android
ORG=com.yourorg PROJECT_NAME=yourapp ./scripts/setup.sh
```

### 必要なもの

| ツール | 用途 |
|---|---|
| Flutter 3.35 以上 | アプリ本体 |
| Python 3.11 以上 | 取り込みパイプライン（外部依存なし） |
| PostgreSQL 15 以上 または Supabase CLI | DB の検証 |

### 接続情報

`app/.env.example` を参照。`--dart-define` で渡す。
クライアントに置いてよいのは公開鍵のみで、service_role key は入れない。

```bash
cd app
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

## 検証

```bash
./scripts/db_test.sh                  # マイグレーション・シード・RLS を実際の Postgres で検証
python scripts/check_consistency.py   # 生成データとアプリコードの整合性
cd tools/ingestion && python -m pytest tests/ -q
cd app && flutter analyze && flutter test
```

## ローカル開発時のデータ投入

検索を動かすには香水レコードが必要。一次データセットのレコードは
再配布しない方針のため（ADR-017）、ローカルで生成する。

```bash
cd tools/ingestion
python -m ingestion.sources.dev_fixture --limit 2000   # .local/ に出力（gitignore 済み）
psql -f .local/dev_perfumes.sql
psql -c "select * from merge_staging_batch('d0000000-0000-4000-8000-000000000001', true);"
```

本番のマスタは公式サイトと楽天ウェブサービス / Amazon PA-API から作る。

## 香水マスタ

香料 497 語・香調 21 種を収録（[tools/ingestion/README.md](tools/ingestion/README.md)）。

産地違い・抽出法違いの表記（`Bulgarian rose` / `Turkish rose absolute` …）は
正規形へ寄せ、元の表記は別名として保持している。
一次ソースに混入していた実在しない香料名は除外済み（ADR-013）。

## リポジトリ履歴について

このプロジェクトは `x-to-notion`（X→Notion 保存 Chrome 拡張）のリポジトリで
書き始め、プロダクト名の確定にあわせて本リポジトリへ移した。
