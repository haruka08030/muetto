#!/usr/bin/env bash
# マイグレーション・シード・RLS ポリシーを実際の PostgreSQL に適用して検証する。
#
#   ./scripts/db_test.sh
#
# 接続先は環境変数で上書きできる（CI ではサービスコンテナを指す）。
#   PGHOST PGPORT PGUSER PGPASSWORD
#
# ローカルで Postgres が無い場合は `supabase start` でも代用できるが、
# このスクリプトは素の PostgreSQL 15+ があれば動く。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_NAME="${DB_NAME:-perfume_app_test}"

export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGUSER="${PGUSER:-postgres}"

psql_admin() { psql -v ON_ERROR_STOP=1 -q -d postgres "$@"; }
psql_db()    { psql -v ON_ERROR_STOP=1 -d "$DB_NAME" "$@"; }

echo "==> テスト用データベースを作り直す: $DB_NAME"
psql_admin -c "drop database if exists $DB_NAME;"
psql_admin -c "create database $DB_NAME;"

echo "==> auth スキーマのスタブを適用"
psql_db -q -f "$ROOT/supabase/tests/bootstrap_auth_stub.sql"

echo "==> マイグレーションを適用"
for f in "$ROOT"/supabase/migrations/*.sql; do
  printf '    %s\n' "$(basename "$f")"
  psql_db -q -f "$f"
done

echo "==> シードを適用"
for f in "$ROOT"/supabase/seed/*.sql; do
  printf '    %s\n' "$(basename "$f")"
  psql_db -q -f "$f"
done

echo "==> シード件数を確認"
psql_db -tA -c "
  select 'accords: '      || count(*) from accords
  union all select 'notes: '        || count(*) from notes
  union all select 'note_aliases: ' || count(*) from note_aliases;"

echo "==> RLS ポリシーを検証"
# テストはデータを投入するため再実行できない。パイプで終了コードが
# 握り潰されないよう PIPESTATUS で psql 側の結果を見る。
set +e
psql_db -f "$ROOT/supabase/tests/rls_test.sql" 2>&1 \
  | grep -E 'ok |FAILED|^---|通過'
status=${PIPESTATUS[0]}
set -e

if [ "$status" -ne 0 ]; then
  echo "==> RLS テストに失敗があります" >&2
  exit 1
fi
echo "==> すべて成功"
