-- staging から本番テーブルへのマージ
-- 参照: docs/data-ingestion.md 4, 6
--
-- 方針:
--   - 検証済み (is_verified = true) のレコードは自動上書きしない。
--     差分は perfume_edit_suggestions に積み、人手の判断に回す。
--   - 未検証レコードは上書きしてよい。
--   - 未知のブランドは自動作成しない。表記ゆれによる重複増殖を防ぐため、
--     unmapped_brands に積んで人手確認に回す。
--   - 解決できなかった香料は unmapped_notes に積む。

-- 取り込みが起点の修正提案は投稿者がいない。
-- RLS の edit_suggestions_read_own は created_by = auth.uid() で判定するため、
-- null のものはユーザーからは見えず service_role からのみ扱える。
alter table perfume_edit_suggestions alter column created_by drop not null;

create table unmapped_brands (
  name       text primary key,
  frequency  integer not null default 1,
  first_seen timestamptz not null default now(),
  last_seen  timestamptz not null default now()
);

alter table unmapped_brands enable row level security;

create function merge_staging_batch(
  target_batch uuid,
  create_missing_brands boolean default false
) returns ingestion_batches
language plpgsql
security definer
set search_path = public
as $$
declare
  row_in         staging_perfumes%rowtype;
  v_brand_id     uuid;
  v_perfume_id   uuid;
  v_slug         text;
  v_existing     perfumes%rowtype;
  v_note_id      uuid;
  v_accord_id    uuid;
  v_raw          text;
  v_pos          note_position;
  v_order        smallint;
  v_result       ingestion_batches;
  n_brands       integer := 0;
  n_created      integer := 0;
  n_updated      integer := 0;
  n_skipped      integer := 0;
  n_unmapped     integer := 0;
begin
  for row_in in
    select * from staging_perfumes where batch_id = target_batch order by id
  loop
    -- ブランドの解決
    select id into v_brand_id from brands where slug = slugify(row_in.brand_name_en);

    if v_brand_id is null then
      if create_missing_brands then
        insert into brands (slug, name_en, name_ja, country, data_source, source_url)
        values (slugify(row_in.brand_name_en), row_in.brand_name_en,
                row_in.brand_name_ja, row_in.brand_country,
                'scraped', row_in.source_url)
        returning id into v_brand_id;
        n_brands := n_brands + 1;
      else
        insert into unmapped_brands (name) values (row_in.brand_name_en)
        on conflict (name) do update
          set frequency = unmapped_brands.frequency + 1, last_seen = now();
        continue;
      end if;
    end if;

    v_slug := slugify(row_in.name_en);

    select * into v_existing from perfumes
    where brand_id = v_brand_id and slug = v_slug
      and concentration = row_in.concentration;

    -- 検証済みレコードは自動上書きせず、修正提案として積む
    if found and v_existing.is_verified then
      insert into perfume_edit_suggestions (perfume_id, payload, reason, created_by, status)
      select v_existing.id,
             to_jsonb(row_in) - 'id' - 'batch_id' - 'created_at',
             format('取り込みバッチ %s による差分', target_batch),
             null, 'pending'
      where to_jsonb(row_in) ->> 'content_hash' is distinct from null;
      n_skipped := n_skipped + 1;
      continue;
    end if;

    if found then
      update perfumes set
        name_en = row_in.name_en,
        name_ja = coalesce(row_in.name_ja, name_ja),
        gender_target = row_in.gender_target,
        release_year = coalesce(row_in.release_year, release_year),
        perfumer = coalesce(row_in.perfumer, perfumer),
        image_url = coalesce(row_in.image_url, image_url),
        source_url = coalesce(row_in.source_url, source_url),
        updated_at = now()
      where id = v_existing.id;
      v_perfume_id := v_existing.id;
      n_updated := n_updated + 1;
    else
      insert into perfumes (brand_id, slug, name_en, name_ja, concentration,
                            gender_target, release_year, perfumer, image_url,
                            data_source, source_url, is_verified)
      values (v_brand_id, v_slug, row_in.name_en, row_in.name_ja,
              row_in.concentration, row_in.gender_target, row_in.release_year,
              row_in.perfumer, row_in.image_url, 'scraped', row_in.source_url, false)
      returning id into v_perfume_id;
      n_created := n_created + 1;
    end if;

    -- 構成は毎回作り直す。部分更新だと古い香料が残る。
    delete from perfume_notes where perfume_id = v_perfume_id;
    delete from perfume_accords where perfume_id = v_perfume_id;

    foreach v_pos in array array['top', 'middle', 'base']::note_position[]
    loop
      v_order := 1;
      foreach v_raw in array (
        case v_pos
          when 'top' then row_in.top_notes
          when 'middle' then row_in.middle_notes
          else row_in.base_notes
        end)
      loop
        v_note_id := resolve_note_id(v_raw);
        if v_note_id is null then
          insert into unmapped_notes (name) values (lower(trim(v_raw)))
          on conflict (name) do update
            set frequency = unmapped_notes.frequency + 1, last_seen = now();
          n_unmapped := n_unmapped + 1;
        else
          insert into perfume_notes (perfume_id, note_id, position, position_order)
          values (v_perfume_id, v_note_id, v_pos, v_order)
          on conflict (perfume_id, note_id, position) do nothing;
        end if;
        v_order := v_order + 1;
      end loop;
    end loop;

    foreach v_raw in array row_in.accord_slugs
    loop
      select id into v_accord_id from accords where slug = slugify(v_raw);
      if v_accord_id is not null then
        insert into perfume_accords (perfume_id, accord_id)
        values (v_perfume_id, v_accord_id)
        on conflict (perfume_id, accord_id) do nothing;
      end if;
    end loop;
  end loop;

  update ingestion_batches set
    brands_created = n_brands,
    perfumes_created = n_created,
    perfumes_updated = n_updated,
    perfumes_skipped = n_skipped,
    notes_unmapped = n_unmapped,
    merged_at = now()
  where id = target_batch
  returning * into v_result;

  return v_result;
end;
$$;

comment on function merge_staging_batch(uuid, boolean) is
  '未知ブランドは既定で作成しない。表記ゆれによるブランドの重複増殖を防ぐため、'
  'unmapped_brands に積んで人手確認に回す。';
