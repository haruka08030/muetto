#!/usr/bin/env bash
# マイグレーション・シード・SQL テストを実際の PostgreSQL に適用して検証する。
#
#   ./scripts/db_test.sh
#
# 接続先は環境変数で上書きできる（CI ではサービスコンテナを指す）。
#   PGHOST PGPORT PGUSER PGPASSWORD
#
# supabase/tests/*_test.sql をそれぞれ専用のデータベースで実行する。
# テストはデータを投入するため、同じ DB を共有すると互いに干渉する。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_PREFIX="${DB_PREFIX:-perfume_app_test}"

export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGUSER="${PGUSER:-postgres}"

psql_admin() { psql -v ON_ERROR_STOP=1 -q -d postgres "$@"; }

# 空のスキーマ + シードを載せた新しいデータベースを作る。
setup_db() {
  local db="$1"
  psql_admin -c "drop database if exists $db;"
  psql_admin -c "create database $db;"

  psql -v ON_ERROR_STOP=1 -q -d "$db" -f "$ROOT/supabase/tests/bootstrap_auth_stub.sql"
  for f in "$ROOT"/supabase/migrations/*.sql; do
    psql -v ON_ERROR_STOP=1 -q -d "$db" -f "$f"
  done
  for f in "$ROOT"/supabase/seed/*.sql; do
    psql -v ON_ERROR_STOP=1 -q -d "$db" -f "$f"
  done
}

echo "==> スキーマとシードを検証"
setup_db "${DB_PREFIX}_base"
psql -v ON_ERROR_STOP=1 -tA -d "${DB_PREFIX}_base" -c "
  select 'accords: '      || count(*) from accords
  union all select 'notes: '        || count(*) from notes
  union all select 'note_aliases: ' || count(*) from note_aliases;"

failed=0
for test_file in "$ROOT"/supabase/tests/*_test.sql; do
  name="$(basename "$test_file" .sql)"
  echo "==> $name"
  setup_db "${DB_PREFIX}_${name}"

  # テストはデータを投入するため再実行できない。パイプで終了コードが
  # 握り潰されないよう PIPESTATUS で psql 側の結果を見る。
  set +e
  psql -v ON_ERROR_STOP=1 -d "${DB_PREFIX}_${name}" -f "$test_file" 2>&1 \
    | grep -E 'ok  |FAILED|^---|通過'
  status=${PIPESTATUS[0]}
  set -e

  if [ "$status" -ne 0 ]; then
    echo "    ✗ $name に失敗があります" >&2
    failed=1
  fi
done

if [ "$failed" -ne 0 ]; then
  echo "==> 失敗したテストがあります" >&2
  exit 1
fi
echo "==> すべて成功"
