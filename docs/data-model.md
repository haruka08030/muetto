# データモデル

対象: Supabase (PostgreSQL 15+)

---

## 1. 全体像

```
                 ┌──────────┐
                 │  brands  │
                 └────┬─────┘
                      │ 1:N
                 ┌────▼─────┐        ┌───────────────┐
        ┌────────┤ perfumes ├────────┤ perfume_notes ├──── notes
        │        └────┬─────┘  1:N   └───────────────┘
        │             │ 1:N
        │        ┌────▼──────────┐
        │        │perfume_accords├──── accords
        │        └───────────────┘
        │
        │ N:1
   ┌────┴────────────┬──────────────────┬─────────────────┐
   │                 │                  │                 │
┌──▼──────────┐ ┌────▼──────────┐ ┌─────▼────────┐ ┌──────▼────────┐
│tasting_logs │ │collection_items│ │wishlist_items│ │perfume_offers │
└──┬──────────┘ └───────────────┘ └──────────────┘ └───────────────┘
   │ 1:N                                                    │ N:1
┌──▼────────┐                                        ┌──────▼───┐
│log_photos │                                        │retailers │
└───────────┘                                        └──────────┘

profiles ──< 上記ユーザー所有テーブルすべて
user_note_scores / user_accord_scores : 分析結果のキャッシュ
```

---

## 2. マスタ系

### `brands`

| カラム | 型 | 備考 |
|---|---|---|
| id | uuid PK | |
| slug | text UNIQUE | 正規化キー（名寄せ用） |
| name_ja | text | 日本語名 |
| name_en | text NOT NULL | 英語名 |
| name_original | text | 原語表記（仏語等） |
| synonyms | text[] | 別名・表記ゆれ |
| country | text | |
| logo_url | text | |
| is_verified | boolean DEFAULT false | |
| created_by | uuid → profiles | ユーザー投稿の場合 |
| created_at / updated_at | timestamptz | |

### `perfumes`

| カラム | 型 | 備考 |
|---|---|---|
| id | uuid PK | |
| brand_id | uuid → brands | |
| slug | text | 名寄せキー（`brand_slug/name_slug/concentration`） |
| name_ja | text | |
| name_en | text NOT NULL | |
| name_original | text | |
| synonyms | text[] | OCR 照合にも使用 |
| concentration | enum | `edc` / `edt` / `edp` / `parfum` / `extrait` / `cologne` / `other` |
| gender_target | enum | `feminine` / `masculine` / `unisex` / `unknown` |
| release_year | int | |
| perfumer | text | 調香師 |
| image_url | text | |
| description | text | 事実ベースの短い説明のみ |
| data_source | enum | `official` / `scraped` / `user` |
| source_url | text | 出典 |
| is_verified | boolean DEFAULT false | |
| created_by | uuid → profiles | |
| created_at / updated_at | timestamptz | |

UNIQUE (brand_id, slug)

### `notes` — 香料マスタ

| カラム | 型 | 備考 |
|---|---|---|
| id | uuid PK | |
| slug | text UNIQUE | |
| name_ja | text NOT NULL | 例: ベルガモット |
| name_en | text NOT NULL | 例: Bergamot |
| synonyms | text[] | 表記ゆれ・別名 |
| family | text | 香料の系統（citrus / floral / woody / spicy / animalic …） |

### `accords` — 香調カテゴリマスタ

| カラム | 型 | 備考 |
|---|---|---|
| id | uuid PK | |
| slug | text UNIQUE | |
| name_ja / name_en | text | 例: ウッディ / Woody |

**notes と accords の違い**: `notes` は個別の香料（ベルガモット、イリス、ウード）。
`accords` は香水全体の性格を表す香調カテゴリ（ウッディ、フローラル、フゼア、グルマン）。
好み分析では両方を独立した特徴量として使う（[preference-algorithm.md](preference-algorithm.md) 参照）。

### `perfume_notes`

| カラム | 型 | 備考 |
|---|---|---|
| perfume_id | uuid → perfumes | |
| note_id | uuid → notes | |
| position | enum | `top` / `middle` / `base` / `unspecified` |
| position_order | int | 同一 position 内の記載順（重要度の代理指標） |

PK (perfume_id, note_id, position)

### `perfume_accords`

| カラム | 型 | 備考 |
|---|---|---|
| perfume_id | uuid → perfumes | |
| accord_id | uuid → accords | |
| strength | numeric | 0.0〜1.0。構成比 |

PK (perfume_id, accord_id)

---

## 3. ユーザー系

### `profiles`

| カラム | 型 | 備考 |
|---|---|---|
| id | uuid PK → auth.users | |
| display_name | text | |
| avatar_url | text | |
| locale | text DEFAULT 'ja' | |
| onboarding_accords | uuid[] | オンボーディングで選んだ好きな香調 |
| onboarding_brands | uuid[] | 同・好きなブランド |
| created_at | timestamptz | |

### `tasting_logs`

| カラム | 型 | 備考 |
|---|---|---|
| id | uuid PK | |
| user_id | uuid → profiles | |
| perfume_id | uuid → perfumes | |
| rating | numeric(2,1) | **1.0〜5.0、0.1 刻み**。CHECK 制約 |
| memo | text | |
| tested_at | date NOT NULL | |
| method | enum | `blotter` / `skin` / `sample` / `owned` |
| scenes | text[] | work / date / daily / night / special |
| seasons | text[] | spring / summer / autumn / winter |
| temperature_band | enum | `cold` / `cool` / `mild` / `hot` |
| longevity | smallint | 1〜5 |
| sillage | smallint | 1〜5 |
| want_to_buy | boolean DEFAULT false | |
| visibility | enum DEFAULT 'private' | `private` / `public`（v2 のコミュニティ機能に備える） |
| created_at / updated_at | timestamptz | |

INDEX (user_id, tested_at DESC), INDEX (perfume_id)

> **注**: 時間経過ごとの個別メモ（トップ／ミドル／ラストの段階別記録）は v1 のスコープ外。
> 追加する場合は `tasting_log_phases (log_id, phase, elapsed_minutes, memo, rating)` を新設する。

### `log_photos`

| カラム | 型 | 備考 |
|---|---|---|
| id | uuid PK | |
| log_id | uuid → tasting_logs ON DELETE CASCADE | |
| storage_path | text | Supabase Storage のパス |
| sort_order | int | |

### `collection_items`

| カラム | 型 | 備考 |
|---|---|---|
| id | uuid PK | |
| user_id | uuid → profiles | |
| perfume_id | uuid → perfumes | |
| acquisition_type | enum | `full_bottle` / `decant` / `sample` / `subscription` / `gift` |
| volume_ml | numeric | |
| remaining_pct | smallint | 0〜100 |
| price | numeric | |
| currency | text DEFAULT 'JPY' | |
| purchased_at | date | |
| purchase_channel | text | |
| status | enum | `active` / `finished` / `disposed` |
| created_at / updated_at | timestamptz | |

### `collection_usage_history`

残量の更新履歴。使い切り予測に使う。

| カラム | 型 |
|---|---|
| id | uuid PK |
| collection_item_id | uuid → collection_items ON DELETE CASCADE |
| remaining_pct | smallint |
| recorded_at | timestamptz |

### `wishlist_items`

| カラム | 型 | 備考 |
|---|---|---|
| id | uuid PK | |
| user_id | uuid → profiles | |
| perfume_id | uuid → perfumes | |
| priority | smallint | |
| memo | text | |
| created_at | timestamptz | |

UNIQUE (user_id, perfume_id)

---

## 4. 分析キャッシュ

好み分析はログ保存のたびにリアルタイム集計せず、Edge Function で再計算して結果を保存する。

### `user_note_scores`

| カラム | 型 | 備考 |
|---|---|---|
| user_id | uuid → profiles | |
| note_id | uuid → notes | |
| preference | numeric | センタリング済みスコア。正＝好き / 負＝苦手 |
| raw_score | numeric | ベイズ補正後の平均評価 |
| sample_size | int | 根拠となったログ件数 |
| updated_at | timestamptz | |

PK (user_id, note_id)

### `user_accord_scores`

`user_note_scores` と同構造（`accord_id` を持つ）。

### `user_note_pair_scores`

配合バランスによる嗜好の違いを捉えるための共起ペア。

| カラム | 型 | 備考 |
|---|---|---|
| user_id | uuid | |
| note_id_a / note_id_b | uuid | `note_id_a < note_id_b` で正規化 |
| preference | numeric | |
| sample_size | int | |
| updated_at | timestamptz | |

PK (user_id, note_id_a, note_id_b)

### `user_profile_state`

| カラム | 型 | 備考 |
|---|---|---|
| user_id | uuid PK | |
| log_count | int | |
| mean_rating | numeric | ユーザーの全評価平均（センタリングに使用） |
| is_analysis_ready | boolean | 分析表示の閾値を超えたか |
| last_computed_at | timestamptz | |

---

## 5. 購入導線

### `retailers`

| カラム | 型 | 備考 |
|---|---|---|
| id | uuid PK | |
| name | text | 例: 楽天市場、カラリア |
| type | enum | `official` / `ec` / `subscription` |
| url_template | text | 例: `https://example.com/search?q={query}&aid={affiliate_id}` |
| affiliate_id | text NULL | 提携前は NULL。**NULL でも `{affiliate_id}` を除去して動作させる** |
| is_active | boolean | |
| sort_order | int | |

### `perfume_offers`

| カラム | 型 | 備考 |
|---|---|---|
| perfume_id | uuid → perfumes | |
| retailer_id | uuid → retailers | |
| url | text | 直リンクがある場合。NULL なら `url_template` から生成 |
| price | numeric | |
| currency | text | |
| updated_at | timestamptz | |

PK (perfume_id, retailer_id)

### `click_events`

| カラム | 型 |
|---|---|
| id | uuid PK |
| user_id | uuid NULL |
| perfume_id | uuid |
| retailer_id | uuid |
| context | text（`detail` / `recommend` / `wishlist`） |
| clicked_at | timestamptz |

---

## 6. データ品質・投稿管理

### `perfume_edit_suggestions`

| カラム | 型 | 備考 |
|---|---|---|
| id | uuid PK | |
| perfume_id | uuid → perfumes | |
| payload | jsonb | 変更提案の差分 |
| reason | text | |
| status | enum | `pending` / `approved` / `rejected` |
| created_by | uuid → profiles | |
| reviewed_by | uuid NULL | |
| created_at / reviewed_at | timestamptz | |

### `ingestion_sources`

スクレイピングによる取り込みの差分管理用。詳細は [data-ingestion.md](data-ingestion.md)。

| カラム | 型 | 備考 |
|---|---|---|
| id | uuid PK | |
| source_name | text | |
| source_url | text UNIQUE | |
| perfume_id | uuid NULL → perfumes | 紐付いた本体レコード |
| content_hash | text | 再取得時の差分検知 |
| raw_payload | jsonb | 正規化前の生データ |
| fetched_at | timestamptz | |

---

## 7. RLS 方針

| テーブル | SELECT | INSERT | UPDATE / DELETE |
|---|---|---|---|
| `brands` `perfumes` `notes` `accords` `perfume_notes` `perfume_accords` | 全員 | 認証済みユーザー | 本人が作成した未検証レコードのみ。検証済みは提案テーブル経由 |
| `retailers` `perfume_offers` | 全員 | 不可（service_role のみ） | 不可 |
| `tasting_logs` `log_photos` `collection_items` `collection_usage_history` `wishlist_items` | `auth.uid() = user_id`（`visibility = 'public'` の場合は全員） | 本人 | 本人 |
| `user_*_scores` `user_profile_state` | 本人 | service_role のみ | service_role のみ |
| `click_events` | 不可 | 認証済み・匿名とも INSERT のみ | 不可 |
| `perfume_edit_suggestions` | 本人＋管理者 | 認証済み | 管理者のみ |
| `ingestion_sources` | service_role のみ | service_role のみ | service_role のみ |

**Storage**: `log-photos` バケットはユーザー ID をプレフィックスに持ち、本人のみ読み書き可。
`perfume-images` バケットは公開読み取り。

---

## 8. 多言語対応の方針

v1 は `name_ja` / `name_en` の 2 カラム方式（UI は日本語のみ）。

3 言語目が必要になった時点で `*_translations (entity_id, locale, name, description)` へ移行できるよう、
**アプリ側は必ずロケール解決関数（`localizedName(entity, locale)`）を経由してアクセスし、
`name_ja` を直接参照しない**こと。この規約を守れば移行はデータ層に閉じる。

---

## 9. インデックス方針（初期）

```sql
-- あいまい検索
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX perfumes_name_trgm ON perfumes USING gin (
  (coalesce(name_ja,'') || ' ' || name_en) gin_trgm_ops);
CREATE INDEX brands_name_trgm ON brands USING gin (
  (coalesce(name_ja,'') || ' ' || name_en) gin_trgm_ops);

-- 交差集計
CREATE INDEX tasting_logs_user_perfume ON tasting_logs (user_id, perfume_id);
CREATE INDEX perfume_notes_note ON perfume_notes (note_id);
CREATE INDEX perfume_accords_accord ON perfume_accords (accord_id);
```
