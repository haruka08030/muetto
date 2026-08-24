-- 拡張と列挙型
-- 参照: docs/data-model.md

create extension if not exists "pgcrypto";
create extension if not exists "pg_trgm";
create extension if not exists "unaccent";

-- 賦香率
create type concentration as enum (
  'edc', 'edt', 'edp', 'parfum', 'extrait', 'cologne', 'other'
);

-- 香水がターゲットとする性別
create type gender_target as enum ('feminine', 'masculine', 'unisex', 'unknown');

-- ノートピラミッドの段
create type note_position as enum ('top', 'middle', 'base', 'unspecified');

-- マスタデータの出所
create type data_source as enum ('official', 'scraped', 'user');

-- 試香の方法
create type tasting_method as enum ('blotter', 'skin', 'sample', 'owned');

-- 試香時の気温帯
create type temperature_band as enum ('cold', 'cool', 'mild', 'hot');

-- ログの公開範囲。v1 は private のみ使用。v2 のコミュニティ機能に備えて定義しておく。
create type log_visibility as enum ('private', 'public');

-- 所持品の入手形態
create type acquisition_type as enum (
  'full_bottle', 'decant', 'sample', 'subscription', 'gift'
);

-- 所持品のステータス
create type collection_status as enum ('active', 'finished', 'disposed');

-- 販売チャネルの種別
create type retailer_type as enum ('official', 'ec', 'subscription');

-- 修正提案のステータス
create type suggestion_status as enum ('pending', 'approved', 'rejected');
