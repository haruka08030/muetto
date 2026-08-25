-- RLS ポリシーの検証。
--
--   psql -f supabase/tests/bootstrap_auth_stub.sql
--   psql -f supabase/migrations/*.sql
--   psql -f supabase/tests/rls_test.sql
--
-- 想定と違う挙動があれば raise exception で落ちる。

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

-- テスト用のユーザーを 2 人作る。
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.test');

do $$ begin perform assert(
  (select count(*) from profiles) = 2,
  'サインアップ時に profiles が自動生成される'
); end $$;

-- 検証用の香水を用意する（service_role 相当で投入）。
insert into brands (id, slug, name_en, is_verified)
values ('aaaaaaaa-0000-0000-0000-000000000001', 'test-brand', 'Test Brand', true);
insert into perfumes (id, brand_id, slug, name_en, is_verified)
values ('bbbbbbbb-0000-0000-0000-000000000001',
        'aaaaaaaa-0000-0000-0000-000000000001', 'test-perfume', 'Test Perfume', true);

-- alice のログを 1 件。
insert into tasting_logs (id, user_id, perfume_id, rating)
values ('cccccccc-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111',
        'bbbbbbbb-0000-0000-0000-000000000001', 4.3);

--------------------------------------------------------------------------------
\echo '--- 評価スケールの制約 ---'

-- 0.1 より細かい値は numeric(2, 1) の精度で丸められる。
insert into tasting_logs (id, user_id, perfume_id, rating)
values ('cccccccc-0000-0000-0000-000000000002',
        '11111111-1111-1111-1111-111111111111',
        'bbbbbbbb-0000-0000-0000-000000000001', 4.25);

do $$ begin perform assert(
  (select rating from tasting_logs where id = 'cccccccc-0000-0000-0000-000000000002')
    = 4.3,
  '0.1 より細かい評価 (4.25) は 0.1 刻みへ丸められる'
); end $$;

delete from tasting_logs where id = 'cccccccc-0000-0000-0000-000000000002';

do $$
declare ok boolean := false;
begin
  begin
    insert into tasting_logs (user_id, perfume_id, rating)
    values ('11111111-1111-1111-1111-111111111111',
            'bbbbbbbb-0000-0000-0000-000000000001', 5.5);
  exception when others then ok := true;
  end;
  perform assert(ok, '範囲外の評価 (5.5) は拒否される');
end $$;

do $$ begin perform assert(
  (select count(*) from tasting_logs where rating = 4.3) = 1,
  '0.1 刻みの評価 (4.3) は保存できる'
); end $$;

--------------------------------------------------------------------------------
\echo '--- 他人のログが見えないこと ---'

set role authenticated;
set request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';

do $$ begin perform assert(
  (select count(*) from tasting_logs) = 0,
  'bob から alice の非公開ログは見えない'
); end $$;

do $$ begin perform assert(
  (select count(*) from notes) > 0,
  'マスタ（香料）は認証済みユーザーから読める'
); end $$;

do $$
declare ok boolean := false;
begin
  begin
    insert into tasting_logs (user_id, perfume_id, rating)
    values ('11111111-1111-1111-1111-111111111111',
            'bbbbbbbb-0000-0000-0000-000000000001', 3.0);
  exception when others then ok := true;
  end;
  perform assert(ok, 'bob は alice 名義のログを作れない');
end $$;

reset role;
reset request.jwt.claim.sub;

--------------------------------------------------------------------------------
\echo '--- 本人のログは見えること ---'

set role authenticated;
set request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

do $$ begin perform assert(
  (select count(*) from tasting_logs) = 1,
  'alice から自分のログは見える'
); end $$;

reset role;
reset request.jwt.claim.sub;

--------------------------------------------------------------------------------
\echo '--- 公開ログは他人からも見えること (v2 に備えた確認) ---'

update tasting_logs set visibility = 'public'
where id = 'cccccccc-0000-0000-0000-000000000001';

set role authenticated;
set request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';

do $$ begin perform assert(
  (select count(*) from tasting_logs) = 1,
  'visibility = public のログは他人からも見える'
); end $$;

reset role;
reset request.jwt.claim.sub;

update tasting_logs set visibility = 'private'
where id = 'cccccccc-0000-0000-0000-000000000001';

--------------------------------------------------------------------------------
\echo '--- 検証済みマスタが改変されないこと ---'

set role authenticated;
set request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';

do $$ begin perform assert(
  (select count(*) from perfumes where name_en = 'Hijacked') = 0,
  '検証済み香水は他人から書き換えられない (更新前)'
); end $$;

update perfumes set name_en = 'Hijacked'
where id = 'bbbbbbbb-0000-0000-0000-000000000001';

reset role;
reset request.jwt.claim.sub;

do $$ begin perform assert(
  (select name_en from perfumes where id = 'bbbbbbbb-0000-0000-0000-000000000001')
    = 'Test Perfume',
  '検証済み香水は他人から書き換えられない (更新後)'
); end $$;

--------------------------------------------------------------------------------
\echo '--- ユーザー投稿は未検証としてのみ作れること ---'

set role authenticated;
set request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';

insert into perfumes (brand_id, slug, name_en, created_by, is_verified)
values ('aaaaaaaa-0000-0000-0000-000000000001', 'bob-perfume', 'Bob Perfume',
        '22222222-2222-2222-2222-222222222222', false);

do $$ begin perform assert(
  (select count(*) from perfumes where slug = 'bob-perfume') = 1,
  'ユーザーは未検証の香水を登録できる'
); end $$;

do $$
declare ok boolean := false;
begin
  begin
    insert into perfumes (brand_id, slug, name_en, created_by, is_verified)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'fake-verified', 'Fake',
            '22222222-2222-2222-2222-222222222222', true);
  exception when others then ok := true;
  end;
  perform assert(ok, 'ユーザーは検証済みフラグを立てて登録できない');
end $$;

reset role;
reset request.jwt.claim.sub;

--------------------------------------------------------------------------------
\echo '--- 分析結果はクライアントから書き込めないこと ---'

insert into user_note_scores (user_id, note_id, preference, raw_score, sample_size)
select '11111111-1111-1111-1111-111111111111', id, 0.5, 4.0, 8
from notes limit 1;

set role authenticated;
set request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

do $$ begin perform assert(
  (select count(*) from user_note_scores) = 1,
  '本人の分析結果は読める'
); end $$;

do $$
declare ok boolean := false;
begin
  begin
    insert into user_note_scores (user_id, note_id, preference, raw_score)
    select '11111111-1111-1111-1111-111111111111', id, 9.9, 9.9
    from notes offset 1 limit 1;
  exception when others then ok := true;
  end;
  perform assert(ok, '分析結果はクライアントから書き込めない');
end $$;

reset role;
reset request.jwt.claim.sub;

--------------------------------------------------------------------------------
\echo '--- 共起ペアの向きが一意であること ---'

do $$
declare ok boolean := false;
  a uuid; b uuid;
begin
  select id into a from notes order by id asc limit 1;
  select id into b from notes order by id desc limit 1;
  begin
    -- note_id_a > note_id_b の順で入れようとすると落ちる
    insert into user_note_pair_scores
      (user_id, note_id_a, note_id_b, preference, interaction)
    values ('11111111-1111-1111-1111-111111111111', b, a, 0.3, 0.6);
  exception when others then ok := true;
  end;
  perform assert(ok, '共起ペアは (小さいID, 大きいID) の順でしか登録できない');
end $$;

\echo ''
\echo 'すべてのアサーションを通過しました。'
