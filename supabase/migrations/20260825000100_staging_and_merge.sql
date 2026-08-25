-- 香水レコードの取り込み: staging と本番へのマージ
-- 参照: docs/data-ingestion.md 4
--
-- 本番テーブルへ直接書き込まない。必ず staging を経由し、
-- 件数・充足率・重複率を確認してからマージする。

create table staging_perfumes (
  id             uuid primary key default gen_random_uuid(),
  batch_id       uuid not null,
  source_name    text not null,
  source_url     text,
  content_hash   text,

  brand_name_en  text not null,
  brand_name_ja  text,
  brand_country  text,

  name_en        text not null,
  name_ja        text,
  concentration  concentration not null default 'other',
  gender_target  gender_target not null default 'unknown',
  release_year   smallint,
  perfumer       text,
  image_url      text,

  -- 香料は正規化前の表記で受ける。マージ時に notes / note_aliases で解決する。
  top_notes      text[] not null default '{}',
  middle_notes   text[] not null default '{}',
  base_notes     text[] not null default '{}',
  accord_slugs   text[] not null default '{}',

  created_at     timestamptz not null default now()
);

create index staging_perfumes_batch on staging_perfumes (batch_id);

alter table staging_perfumes enable row level security;
-- ポリシーを作らない = service_role 以外からは触れない。

-- 取り込みバッチの記録。マージ結果を残して、後から検証できるようにする。
create table ingestion_batches (
  id             uuid primary key default gen_random_uuid(),
  source_name    text not null,
  staged_count   integer not null default 0,
  brands_created integer not null default 0,
  perfumes_created integer not null default 0,
  perfumes_updated integer not null default 0,
  perfumes_skipped integer not null default 0,
  notes_unmapped integer not null default 0,
  started_at     timestamptz not null default now(),
  merged_at      timestamptz
);

alter table ingestion_batches enable row level security;

comment on column ingestion_batches.perfumes_skipped is
  '検証済みのため自動更新しなかった件数。差分は perfume_edit_suggestions に積む。';


-- 名寄せキー。ingestion 側の slugify と同じ規則で作る。
-- アクセント記号を落とし、英数字以外をハイフンに畳む。
create function slugify(value text) returns text
language sql immutable strict
as $$
  select trim(both '-' from
    regexp_replace(
      lower(translate(
        unaccent(value),
        '''’`', '   '
      )),
      '[^a-z0-9]+', '-', 'g'))
$$;

comment on function slugify(text) is
  'tools/ingestion/ingestion/normalize.py の slugify と同じ結果を返すこと。';


-- 香料の表記を正規形の note_id へ解決する。
-- 直接一致 → 別名一致の順に見る。解決できなければ null。
create function resolve_note_id(raw_name text) returns uuid
language sql stable
as $$
  select coalesce(
    (select n.id from notes n where n.slug = slugify(raw_name)),
    (select a.note_id from note_aliases a where a.alias = lower(trim(raw_name)))
  )
$$;
