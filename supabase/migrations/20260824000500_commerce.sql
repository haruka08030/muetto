-- 購入導線とクリック計測
-- 参照: docs/data-model.md 5, ADR-010

create table retailers (
  id           uuid primary key default gen_random_uuid(),
  slug         text not null unique,
  name         text not null,
  type         retailer_type not null,
  url_template text not null,
  affiliate_id text,
  is_active    boolean not null default true,
  sort_order   smallint not null default 0,
  created_at   timestamptz not null default now()
);

comment on column retailers.url_template is
  '{query} と {affiliate_id} を差し込むテンプレート。提携前は affiliate_id が null。';
comment on column retailers.affiliate_id is
  'null のままでも導線として機能させること（ADR-010）。';

create table perfume_offers (
  perfume_id  uuid not null references perfumes (id) on delete cascade,
  retailer_id uuid not null references retailers (id) on delete cascade,
  url         text,
  price       numeric(10, 2) check (price is null or price >= 0),
  currency    text not null default 'JPY',
  updated_at  timestamptz not null default now(),
  primary key (perfume_id, retailer_id)
);

comment on column perfume_offers.url is
  '直リンクがある場合のみ。null なら retailers.url_template から生成する。';

create table click_events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references profiles (id) on delete set null,
  perfume_id  uuid not null references perfumes (id) on delete cascade,
  retailer_id uuid not null references retailers (id) on delete cascade,
  context     text not null check (context in ('detail', 'recommend', 'wishlist', 'collection')),
  clicked_at  timestamptz not null default now()
);

create index click_events_clicked_at on click_events (clicked_at desc);
