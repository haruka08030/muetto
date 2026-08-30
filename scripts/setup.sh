#!/usr/bin/env bash
# ローカル開発環境のセットアップ。
#
#   ./scripts/setup.sh
#
# 冪等。何度実行しても同じ状態になる。
# 既にあるものは飛ばし、足りないものだけ用意する。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# プラットフォーム生成に使う値。アプリ名が決まったら変更する。
ORG="${ORG:-com.example}"
PROJECT_NAME="${PROJECT_NAME:-muetto}"

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

missing=0
need() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "$1 … $(command -v "$1")"
  else
    warn "$1 が見つかりません — $2"
    missing=1
  fi
}

step "必要なツールの確認"
need flutter "https://docs.flutter.dev/get-started/install （3.35 以上）"
need python3 "3.11 以上"
need git     "—"

# 任意。無くても Flutter とテストは動く。
if command -v supabase >/dev/null 2>&1; then
  ok "supabase … $(command -v supabase)"
else
  warn "supabase CLI が未導入 — ローカル DB を使うなら必要（brew install supabase/tap/supabase）"
fi

if [ "$missing" -ne 0 ]; then
  echo
  echo "必須ツールが足りません。上記を入れてからやり直してください。" >&2
  exit 1
fi

step "Flutter プラットフォームの雛形を生成"
cd "$ROOT"
if [ -d ios ] && [ -d android ]; then
  ok "ios/ と android/ は生成済み"
else
  # flutter create は既存ファイルを上書きしない（検証済み）。
  # 足りないものだけを補う。
  flutter create --platforms=ios,android --org "$ORG" --project-name "$PROJECT_NAME" . >/dev/null
  ok "ios/ と android/ を生成（Bundle ID: $ORG.$PROJECT_NAME）"

  # flutter create が置いていくテンプレートを消す。
  # widget_test.dart は存在しないクラスを参照するため flutter analyze が落ちる。
  # ルート直下で実行するため README.md は消さない（プロジェクトの README を守る）。
  rm -f test/widget_test.dart ./*.iml
  ok "テンプレートの残骸を削除"
fi

step "Dart の依存を取得"
flutter pub get >/dev/null
ok "pub get 完了"

step "香水マスタの生成物を確認"
cd "$ROOT/tools/ingestion"
if [ -f data/notes_master.csv ] && [ -f "$ROOT/supabase/seed/0001_notes_accords.sql" ]; then
  ok "香料マスタとシードはリポジトリに同梱済み（再生成は不要）"
else
  warn "生成物が見当たりません。python -m ingestion.build_masters を実行してください"
fi

step "確認"
cd "$ROOT"
echo "  ./scripts/db_test.sh                 DB マイグレーション・RLS の検証（要 PostgreSQL）"
echo "  python3 scripts/check_consistency.py  生成データとアプリコードの整合性"
echo "  (cd tools/ingestion && python3 -m pytest tests/ -q)"
echo "  flutter analyze && flutter test"

step "次にやること"
cat <<'NEXT'
  1. Supabase プロジェクトを作る（リージョンは ap-northeast-1 / 東京）
     https://supabase.com/dashboard

  2. スキーマを流す
       supabase link --project-ref <project-ref>
       supabase db push

  3. 開発用の香水データを入れる（任意。検索画面を動かしたい場合）
       cd tools/ingestion
       python3 -m ingestion.sources.dev_fixture --limit 2000
       psql "$DATABASE_URL" -f .local/dev_perfumes.sql
       psql "$DATABASE_URL" -c "select * from merge_staging_batch('d0000000-0000-4000-8000-000000000001', true);"

  4. アプリを起動
       flutter run \
         --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
         --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
NEXT
echo
