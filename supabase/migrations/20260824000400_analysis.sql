-- 好み分析のキャッシュ
-- 参照: docs/preference-algorithm.md 8

create table user_profile_state (
  user_id           uuid primary key references profiles (id) on delete cascade,
  log_count         integer not null default 0,
  mean_rating       numeric(3, 2),
  is_analysis_ready boolean not null default false,
  last_computed_at  timestamptz
);

comment on column user_profile_state.mean_rating is
  'センタリングに使うユーザー自身の平均評価。';

create table user_note_scores (
  user_id     uuid not null references profiles (id) on delete cascade,
  note_id     uuid not null references notes (id) on delete cascade,
  preference  numeric(4, 3) not null,
  raw_score   numeric(4, 3) not null,
  sample_size integer not null default 0,
  updated_at  timestamptz not null default now(),
  primary key (user_id, note_id)
);

comment on column user_note_scores.preference is
  'センタリング済みスコア。正なら好き、負なら苦手。';

create table user_accord_scores (
  user_id     uuid not null references profiles (id) on delete cascade,
  accord_id   uuid not null references accords (id) on delete cascade,
  preference  numeric(4, 3) not null,
  raw_score   numeric(4, 3) not null,
  sample_size integer not null default 0,
  updated_at  timestamptz not null default now(),
  primary key (user_id, accord_id)
);

-- 香料の共起ペア。配合バランスによる嗜好の違いを捉える（ADR-009）。
create table user_note_pair_scores (
  user_id     uuid not null references profiles (id) on delete cascade,
  note_id_a   uuid not null references notes (id) on delete cascade,
  note_id_b   uuid not null references notes (id) on delete cascade,
  preference  numeric(4, 3) not null,
  interaction numeric(4, 3) not null,
  sample_size integer not null default 0,
  updated_at  timestamptz not null default now(),
  primary key (user_id, note_id_a, note_id_b),
  -- ペアの向きを一意にする。(A,B) と (B,A) の重複を防ぐ。
  constraint user_note_pair_scores_ordered check (note_id_a < note_id_b)
);

comment on column user_note_pair_scores.interaction is
  '構成香料単体のスコアからの乖離。これが大きいときだけ UI に提示する。';

-- 再計算キュー。ログの変更時に積み、Edge Function が消化する。
create table analysis_queue (
  user_id      uuid primary key references profiles (id) on delete cascade,
  enqueued_at  timestamptz not null default now(),
  processed_at timestamptz
);

-- レコメンドへの否定フィードバック。パラメータ調整の唯一の教師信号になるため v1 から持つ。
create table recommendation_feedback (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references profiles (id) on delete cascade,
  perfume_id uuid not null references perfumes (id) on delete cascade,
  is_useful  boolean not null,
  created_at timestamptz not null default now(),
  unique (user_id, perfume_id)
);
