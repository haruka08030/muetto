-- ユーザーデータ（プロフィール・試香ログ・コレクション・ウィッシュリスト）
-- 参照: docs/data-model.md 3

create table profiles (
  id                  uuid primary key references auth.users (id) on delete cascade,
  display_name        text,
  avatar_url          text,
  locale              text not null default 'ja',
  onboarding_accords  uuid[] not null default '{}',
  onboarding_brands   uuid[] not null default '{}',
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- サインアップ時に profiles を自動生成する。
create function handle_new_user() returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data ->> 'display_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

create table tasting_logs (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references profiles (id) on delete cascade,
  perfume_id       uuid not null references perfumes (id) on delete cascade,
  rating           numeric(2, 1) not null
    check (rating >= 1.0 and rating <= 5.0),
  memo             text,
  tested_at        date not null default current_date,
  method           tasting_method,
  scenes           text[] not null default '{}',
  seasons          text[] not null default '{}',
  temperature_band temperature_band,
  longevity        smallint check (longevity between 1 and 5),
  sillage          smallint check (sillage between 1 and 5),
  want_to_buy      boolean not null default false,
  visibility       log_visibility not null default 'private',
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- 0.1 刻みは numeric(2, 1) の精度そのもので保証される。
-- 4.25 のような値は保存時に 4.3 へ丸められるため、別途 CHECK 制約は置かない。
comment on column tasting_logs.rating is
  '総合評価。1.0〜5.0 の 0.1 刻み（ADR-004）。numeric(2, 1) の精度で刻みを担保する。';

create table log_photos (
  id           uuid primary key default gen_random_uuid(),
  log_id       uuid not null references tasting_logs (id) on delete cascade,
  storage_path text not null,
  sort_order   smallint not null default 0,
  created_at   timestamptz not null default now()
);

create table collection_items (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references profiles (id) on delete cascade,
  perfume_id       uuid not null references perfumes (id) on delete cascade,
  acquisition_type acquisition_type not null default 'full_bottle',
  volume_ml        numeric(6, 2) check (volume_ml is null or volume_ml > 0),
  remaining_pct    smallint not null default 100
    check (remaining_pct between 0 and 100),
  price            numeric(10, 2) check (price is null or price >= 0),
  currency         text not null default 'JPY',
  purchased_at     date,
  purchase_channel text,
  status           collection_status not null default 'active',
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- 残量の更新履歴。使い切り時期の推定に使う。
create table collection_usage_history (
  id                 uuid primary key default gen_random_uuid(),
  collection_item_id uuid not null
    references collection_items (id) on delete cascade,
  remaining_pct      smallint not null check (remaining_pct between 0 and 100),
  recorded_at        timestamptz not null default now()
);

create table wishlist_items (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references profiles (id) on delete cascade,
  perfume_id uuid not null references perfumes (id) on delete cascade,
  priority   smallint not null default 3 check (priority between 1 and 5),
  memo       text,
  created_at timestamptz not null default now(),
  unique (user_id, perfume_id)
);
