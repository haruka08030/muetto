-- データ品質管理（修正提案・取り込み履歴）
-- 参照: docs/data-model.md 6, docs/data-ingestion.md

create table perfume_edit_suggestions (
  id          uuid primary key default gen_random_uuid(),
  perfume_id  uuid not null references perfumes (id) on delete cascade,
  payload     jsonb not null,
  reason      text,
  status      suggestion_status not null default 'pending',
  created_by  uuid not null references profiles (id) on delete cascade,
  reviewed_by uuid references profiles (id) on delete set null,
  created_at  timestamptz not null default now(),
  reviewed_at timestamptz
);

create index perfume_edit_suggestions_pending
  on perfume_edit_suggestions (created_at)
  where status = 'pending';

-- スクレイピング取り込みの差分管理。
create table ingestion_sources (
  id           uuid primary key default gen_random_uuid(),
  source_name  text not null,
  source_url   text not null unique,
  perfume_id   uuid references perfumes (id) on delete set null,
  content_hash text not null,
  raw_payload  jsonb,
  fetched_at   timestamptz not null default now()
);

comment on column ingestion_sources.content_hash is
  '再取得時の差分検知に使う。変化がなければ以降の処理をスキップする。';

-- 香料マスタに載せられなかった語。定期的に人手でレビューする。
create table unmapped_notes (
  name       text primary key,
  frequency  integer not null default 1,
  first_seen timestamptz not null default now(),
  last_seen  timestamptz not null default now()
);
