-- 行レベルセキュリティ
-- 参照: docs/data-model.md 7
--
-- 方針:
--   マスタ    … 全員が読める。認証済みユーザーが追加できる（未検証として入る）。
--                検証済みレコードの更新は修正提案テーブル経由。
--   ユーザー  … 本人のみ。visibility = 'public' のログだけ例外的に全員が読める。
--   分析結果  … 本人が読める。書き込みは service_role のみ。

alter table brands                   enable row level security;
alter table perfumes                 enable row level security;
alter table notes                    enable row level security;
alter table note_aliases             enable row level security;
alter table accords                  enable row level security;
alter table perfume_notes            enable row level security;
alter table perfume_accords          enable row level security;
alter table profiles                 enable row level security;
alter table tasting_logs             enable row level security;
alter table log_photos               enable row level security;
alter table collection_items         enable row level security;
alter table collection_usage_history enable row level security;
alter table wishlist_items           enable row level security;
alter table user_profile_state       enable row level security;
alter table user_note_scores         enable row level security;
alter table user_accord_scores       enable row level security;
alter table user_note_pair_scores    enable row level security;
alter table analysis_queue           enable row level security;
alter table recommendation_feedback  enable row level security;
alter table retailers                enable row level security;
alter table perfume_offers           enable row level security;
alter table click_events             enable row level security;
alter table perfume_edit_suggestions enable row level security;
alter table ingestion_sources        enable row level security;
alter table unmapped_notes           enable row level security;

-- ---------------------------------------------------------------- マスタ ----
create policy brands_read on brands for select using (true);
create policy brands_insert on brands for insert to authenticated
  with check (created_by = auth.uid() and is_verified = false);
create policy brands_update_own on brands for update to authenticated
  using (created_by = auth.uid() and is_verified = false)
  with check (created_by = auth.uid() and is_verified = false);

create policy perfumes_read on perfumes for select using (true);
create policy perfumes_insert on perfumes for insert to authenticated
  with check (created_by = auth.uid() and is_verified = false);
create policy perfumes_update_own on perfumes for update to authenticated
  using (created_by = auth.uid() and is_verified = false)
  with check (created_by = auth.uid() and is_verified = false);

create policy notes_read on notes for select using (true);
create policy note_aliases_read on note_aliases for select using (true);
create policy accords_read on accords for select using (true);

-- 香水の構成は、その香水を作った本人が未検証のうちだけ編集できる。
create policy perfume_notes_read on perfume_notes for select using (true);
create policy perfume_notes_write on perfume_notes for all to authenticated
  using (exists (
    select 1 from perfumes p
    where p.id = perfume_id and p.created_by = auth.uid() and p.is_verified = false))
  with check (exists (
    select 1 from perfumes p
    where p.id = perfume_id and p.created_by = auth.uid() and p.is_verified = false));

create policy perfume_accords_read on perfume_accords for select using (true);
create policy perfume_accords_write on perfume_accords for all to authenticated
  using (exists (
    select 1 from perfumes p
    where p.id = perfume_id and p.created_by = auth.uid() and p.is_verified = false))
  with check (exists (
    select 1 from perfumes p
    where p.id = perfume_id and p.created_by = auth.uid() and p.is_verified = false));

-- ------------------------------------------------------------ ユーザー ----
create policy profiles_read_own on profiles for select to authenticated
  using (id = auth.uid());
create policy profiles_update_own on profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

create policy tasting_logs_read on tasting_logs for select
  using (user_id = auth.uid() or visibility = 'public');
create policy tasting_logs_insert on tasting_logs for insert to authenticated
  with check (user_id = auth.uid());
create policy tasting_logs_update on tasting_logs for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy tasting_logs_delete on tasting_logs for delete to authenticated
  using (user_id = auth.uid());

create policy log_photos_all on log_photos for all to authenticated
  using (exists (
    select 1 from tasting_logs l where l.id = log_id and l.user_id = auth.uid()))
  with check (exists (
    select 1 from tasting_logs l where l.id = log_id and l.user_id = auth.uid()));

create policy collection_items_all on collection_items for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy collection_usage_history_all on collection_usage_history
  for all to authenticated
  using (exists (
    select 1 from collection_items c
    where c.id = collection_item_id and c.user_id = auth.uid()))
  with check (exists (
    select 1 from collection_items c
    where c.id = collection_item_id and c.user_id = auth.uid()));

create policy wishlist_items_all on wishlist_items for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- -------------------------------------------------------------- 分析 ----
-- 書き込みポリシーを作らないことで、service_role 以外は書けない。
create policy user_profile_state_read on user_profile_state for select
  to authenticated using (user_id = auth.uid());
create policy user_note_scores_read on user_note_scores for select
  to authenticated using (user_id = auth.uid());
create policy user_accord_scores_read on user_accord_scores for select
  to authenticated using (user_id = auth.uid());
create policy user_note_pair_scores_read on user_note_pair_scores for select
  to authenticated using (user_id = auth.uid());

create policy recommendation_feedback_all on recommendation_feedback
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ------------------------------------------------------------ 購入導線 ----
create policy retailers_read on retailers for select using (is_active);
create policy perfume_offers_read on perfume_offers for select using (true);

-- クリック計測は書き込み専用。読み出しは service_role のみ。
create policy click_events_insert on click_events for insert
  to anon, authenticated
  with check (user_id is null or user_id = auth.uid());

-- ------------------------------------------------------------ 品質管理 ----
create policy edit_suggestions_read_own on perfume_edit_suggestions
  for select to authenticated using (created_by = auth.uid());
create policy edit_suggestions_insert on perfume_edit_suggestions
  for insert to authenticated
  with check (created_by = auth.uid() and status = 'pending');

-- ingestion_sources / unmapped_notes / analysis_queue はポリシーを作らない。
-- RLS 有効かつポリシー無し = service_role 以外からは一切アクセスできない。
