-- 取り込みマージと検索の検証。
-- 一次データには依存せず、合成フィクスチャだけで完結させる。

\set ON_ERROR_STOP on

create or replace function assert(condition boolean, label text) returns void
language plpgsql as $$
begin
  if condition then
    raise notice '  ok   %', label;
  else
    raise exception 'FAILED: %', label;
  end if;
end;
$$;

\echo '--- slugify が ingestion 側と同じ結果を返すこと ---'

do $$ begin
  perform assert(slugify('Fougère') = 'fougere', 'アクセント記号を落とす');
  perform assert(slugify('Ylang-Ylang') = 'ylang-ylang', '既存のハイフンは保つ');
  perform assert(slugify('Lily of the valley') = 'lily-of-the-valley', '空白をハイフンにする');
  perform assert(slugify('L''Eau') = 'l-eau', 'アポストロフィを区切りにする');
end $$;

\echo '--- 香料の解決 ---'

do $$ begin
  perform assert(resolve_note_id('Rose') is not null, '正規形で解決できる');
  perform assert(resolve_note_id('Bulgarian rose') = resolve_note_id('Rose'),
                 '産地違いの別名が同じ正規形に解決される');
  perform assert(resolve_note_id('Agarwood') = resolve_note_id('Oud'),
                 '別称が正規形に解決される');
  perform assert(resolve_note_id('ZZZ 存在しない香料') is null,
                 '未知の香料は null');
end $$;

--------------------------------------------------------------------------------
\echo '--- 未知ブランドは自動作成しない ---'

insert into ingestion_batches (id, source_name, staged_count)
values ('dddddddd-0000-0000-0000-000000000001', 'test-fixture', 2);

insert into staging_perfumes
  (batch_id, source_name, brand_name_en, name_en, name_ja, concentration,
   top_notes, middle_notes, base_notes, accord_slugs, release_year)
values
  ('dddddddd-0000-0000-0000-000000000001', 'test-fixture',
   'Fixture Maison', 'Rose Nocturne', 'ローズ ノクターン', 'edp',
   array['Bulgarian rose', 'Sicilian bergamot'],
   array['Jasmine'],
   array['Agarwood', 'ZZZ 存在しない香料'],
   array['floral', 'woody'], 2019),
  ('dddddddd-0000-0000-0000-000000000001', 'test-fixture',
   'Fixture Maison', 'Vetiver Brut', null, 'edt',
   array['Grapefruit'], array['Vetiver'], array['Cedarwood'],
   array['woody', 'fresh'], 2021);

select merge_staging_batch('dddddddd-0000-0000-0000-000000000001') \gset merged1_

do $$ begin
  perform assert((select count(*) from perfumes) = 0,
                 '既定ではブランドが無いと香水を作らない');
  perform assert((select count(*) from unmapped_brands where name = 'Fixture Maison') = 1,
                 '未知ブランドは unmapped_brands に積まれる');
end $$;

\echo '--- create_missing_brands = true でマージする ---'

select merge_staging_batch('dddddddd-0000-0000-0000-000000000001', true) \gset merged2_

do $$
declare b record;
begin
  select * into b from ingestion_batches where id = 'dddddddd-0000-0000-0000-000000000001';
  perform assert(b.brands_created = 1, 'ブランドが 1 件作られる');
  perform assert(b.perfumes_created = 2, '香水が 2 件作られる');
  perform assert(b.notes_unmapped = 1, '解決できなかった香料が 1 件記録される');
  perform assert(b.merged_at is not null, 'マージ日時が記録される');
end $$;

do $$ begin
  perform assert(
    (select count(*) from unmapped_notes where name = 'zzz 存在しない香料') = 1,
    '未知の香料は unmapped_notes に積まれる');
  perform assert(
    (select count(*) from perfumes where is_verified) = 0,
    '取り込んだ香水は未検証として入る');
end $$;

\echo '--- 別名がひとつの正規形に畳まれていること ---'

do $$
declare pid uuid;
begin
  select id into pid from perfumes where slug = 'rose-nocturne';
  perform assert(
    exists (select 1 from perfume_notes pn
            where pn.perfume_id = pid
              and pn.note_id = resolve_note_id('Rose')
              and pn.position = 'top'),
    'Bulgarian rose が rose としてトップに入る');
  perform assert(
    exists (select 1 from perfume_notes pn
            where pn.perfume_id = pid
              and pn.note_id = resolve_note_id('Oud')
              and pn.position = 'base'),
    'Agarwood が oud としてラストに入る');
  perform assert(
    (select count(*) from perfume_accords where perfume_id = pid) = 2,
    '香調が 2 件紐づく');
end $$;

\echo '--- ノートピラミッドの並び ---'

do $$
declare rows text[];
begin
  select array_agg(name_en order by ord)
    into rows
  from (
    select name_en, row_number() over () as ord
    from perfume_note_pyramid((select id from perfumes where slug = 'rose-nocturne'))
  ) t;
  perform assert(rows[1] = 'rose' and rows[2] = 'bergamot',
                 'トップが記載順に並ぶ');
  perform assert(rows[array_length(rows, 1)] = 'oud',
                 'ラストが最後に来る');
end $$;

--------------------------------------------------------------------------------
\echo '--- 検証済みレコードは自動上書きされない ---'

-- name_ja は変えずに検証済みにする。後続の検索テストがこの名前を使うため。
update perfumes set is_verified = true where slug = 'rose-nocturne';

insert into ingestion_batches (id, source_name, staged_count)
values ('dddddddd-0000-0000-0000-000000000002', 'test-fixture', 1);

insert into staging_perfumes
  (batch_id, source_name, content_hash, brand_name_en, name_en, name_ja, concentration)
values
  ('dddddddd-0000-0000-0000-000000000002', 'test-fixture', 'hash-1',
   'Fixture Maison', 'Rose Nocturne', '書き換えを試みる名前', 'edp');

select merge_staging_batch('dddddddd-0000-0000-0000-000000000002', true) \gset merged3_

do $$ begin
  perform assert(
    (select name_ja from perfumes where slug = 'rose-nocturne') = 'ローズ ノクターン',
    '検証済みの香水は取り込みで書き換わらない');
  perform assert(
    (select perfumes_skipped from ingestion_batches
     where id = 'dddddddd-0000-0000-0000-000000000002') = 1,
    'スキップ件数が記録される');
  perform assert(
    (select count(*) from perfume_edit_suggestions where status = 'pending') = 1,
    '差分が修正提案として積まれる');
end $$;

--------------------------------------------------------------------------------
\echo '--- 検索 ---'

do $$ begin
  perform assert(
    (select count(*) from search_perfumes('Rose Nocturne')) = 1,
    '製品名の完全一致で見つかる');
  perform assert(
    (select count(*) from search_perfumes('rose nocturne')) = 1,
    '大文字小文字を区別しない');
  perform assert(
    (select count(*) from search_perfumes('ローズ ノクターン')) = 1,
    '日本語名で見つかる');
  perform assert(
    (select count(*) from search_perfumes('Fixture Maison')) = 2,
    'ブランド名でそのブランドの香水がすべて出る');
  perform assert(
    (select count(*) from search_perfumes('Rose Noctrune')) >= 1,
    '綴り間違いでもあいまい一致で見つかる');
  perform assert(
    (select count(*) from search_perfumes('まったく無関係な文字列')) = 0,
    '無関係な語では何も返さない');
end $$;

\echo '--- 検索: 絞り込み ---'

do $$
declare rose_id uuid; woody_id uuid;
begin
  rose_id := resolve_note_id('Rose');
  select id into woody_id from accords where slug = 'woody';

  perform assert(
    (select count(*) from search_perfumes(null, note_ids => array[rose_id])) = 1,
    '香料で絞り込める');
  perform assert(
    (select count(*) from search_perfumes(null, accord_ids => array[woody_id])) = 2,
    '香調で絞り込める');
  perform assert(
    (select count(*) from search_perfumes(
       null, note_ids => array[rose_id, resolve_note_id('Vetiver')])) = 0,
    '複数の香料は AND で効く');
  perform assert(
    (select count(*) from search_perfumes(
       null, concentrations => array['edt']::concentration[])) = 1,
    '賦香率で絞り込める');
  perform assert(
    (select count(*) from search_perfumes(null, year_from => 2020::smallint)) = 1,
    '発売年で絞り込める');
  perform assert(
    (select count(*) from search_perfumes(null, include_unverified => false)) = 1,
    '未検証を除外できる');
end $$;

\echo '--- 検索: 検証済みが優先されること ---'

do $$
declare first_row record;
begin
  select * into first_row from search_perfumes('Fixture Maison') limit 1;
  perform assert(first_row.is_verified,
                 '同じスコアなら検証済みが先に来る');
end $$;

\echo '--- 検索: ページングと上限 ---'

do $$ begin
  perform assert((select count(*) from search_perfumes(null, max_results => 1)) = 1,
                 'max_results が効く');
  perform assert((select count(*) from search_perfumes(null, max_results => 1, skip => 1)) = 1,
                 'skip が効く');
  perform assert(
    (select id from search_perfumes(null, max_results => 1))
      is distinct from
    (select id from search_perfumes(null, max_results => 1, skip => 1)),
    'skip で別のレコードが返る');
  perform assert((select count(*) from search_perfumes(null, max_results => 9999)) = 2,
                 'max_results は 100 で頭打ちにされ、例外にはならない');
end $$;

\echo ''
\echo 'すべてのアサーションを通過しました。'
