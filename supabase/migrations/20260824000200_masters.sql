-- 香水マスタ（ブランド・香水・香料・香調）
-- 参照: docs/data-model.md 2

create table brands (
  id            uuid primary key default gen_random_uuid(),
  slug          text not null unique,
  name_ja       text,
  name_en       text not null,
  name_original text,
  synonyms      text[] not null default '{}',
  country       text,
  logo_url      text,
  data_source   data_source not null default 'user',
  source_url    text,
  is_verified   boolean not null default false,
  created_by    uuid,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

comment on column brands.slug is '名寄せキー。正規化した英語名から生成する。';

create table perfumes (
  id            uuid primary key default gen_random_uuid(),
  brand_id      uuid not null references brands (id) on delete restrict,
  slug          text not null,
  name_ja       text,
  name_en       text not null,
  name_original text,
  synonyms      text[] not null default '{}',
  concentration concentration not null default 'other',
  gender_target gender_target not null default 'unknown',
  release_year  smallint,
  perfumer      text,
  image_url     text,
  description   text,
  data_source   data_source not null default 'user',
  source_url    text,
  is_verified   boolean not null default false,
  created_by    uuid,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint perfumes_release_year_range
    check (release_year is null or release_year between 1700 and 2200),
  unique (brand_id, slug, concentration)
);

comment on column perfumes.synonyms is 'OCR の照合にも使う表記ゆれの集合。';

-- 香料マスタ。正規形のみを保持し、表記ゆれは note_aliases に逃がす。
create table notes (
  id       uuid primary key default gen_random_uuid(),
  slug     text not null unique,
  name_ja  text,
  name_en  text not null,
  family   text not null,
  needs_review boolean not null default false,
  created_at timestamptz not null default now()
);

comment on table notes is
  '香料の正規形。産地違い・抽出法違いの表記は note_aliases 経由でここへ寄せる。';
comment on column notes.needs_review is
  '一次ソースでの出所が疑わしく、人手確認が必要なもの。';

-- 別名 → 正規形。取り込みと検索の名寄せに使う。
create table note_aliases (
  alias    text primary key,
  note_id  uuid not null references notes (id) on delete cascade
);

-- 香調アコード。固定リストとして扱い、みだりに増やさない。
create table accords (
  id      uuid primary key default gen_random_uuid(),
  slug    text not null unique,
  name_ja text,
  name_en text not null,
  sort_order smallint not null default 0
);

create table perfume_notes (
  perfume_id     uuid not null references perfumes (id) on delete cascade,
  note_id        uuid not null references notes (id) on delete cascade,
  position       note_position not null default 'unspecified',
  position_order smallint not null default 1,
  primary key (perfume_id, note_id, position)
);

comment on column perfume_notes.position_order is
  '同じ段の中での記載順。若いほど主要な香料とみなし、分析で重みを付ける。';

create table perfume_accords (
  perfume_id uuid not null references perfumes (id) on delete cascade,
  accord_id  uuid not null references accords (id) on delete cascade,
  strength   numeric(4, 3) not null default 1.000
    check (strength >= 0 and strength <= 1),
  primary key (perfume_id, accord_id)
);
