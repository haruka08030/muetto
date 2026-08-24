-- 検索・集計用インデックス
-- 参照: docs/data-model.md 9

-- あいまい検索（表記ゆれ・OCR の誤認識に耐えるため）
create index brands_name_trgm on brands
  using gin ((coalesce(name_ja, '') || ' ' || name_en) gin_trgm_ops);

create index perfumes_name_trgm on perfumes
  using gin ((coalesce(name_ja, '') || ' ' || name_en) gin_trgm_ops);

create index notes_name_trgm on notes
  using gin ((coalesce(name_ja, '') || ' ' || name_en) gin_trgm_ops);

create index note_aliases_trgm on note_aliases using gin (alias gin_trgm_ops);

-- 検索結果は検証済みを優先するため、フィルタ用に持つ
create index perfumes_brand_verified on perfumes (brand_id, is_verified);
create index perfumes_verified_created on perfumes (is_verified, created_at desc);

-- 交差集計（好み分析）
create index tasting_logs_user_tested on tasting_logs (user_id, tested_at desc);
create index tasting_logs_user_perfume on tasting_logs (user_id, perfume_id);
create index tasting_logs_perfume on tasting_logs (perfume_id);
create index perfume_notes_note on perfume_notes (note_id);
create index perfume_accords_accord on perfume_accords (accord_id);

create index collection_items_user_status on collection_items (user_id, status);
create index wishlist_items_user on wishlist_items (user_id, created_at desc);
create index log_photos_log on log_photos (log_id, sort_order);
