-- 香水検索
-- 参照: docs/requirements.md 5.2, 6（検索結果の初回表示 1 秒以内）
--
-- 要件:
--   - ブランド名・製品名を日本語/英語/原語/別名にわたって横断する
--   - 表記ゆれと OCR の誤認識に耐えるため pg_trgm のあいまい一致を併用する
--   - 検証済みデータを優先し、未検証は下位に置く
--   - 香調・香料・ブランド・賦香率・性別・発売年で絞り込める

-- 検索対象をひとつの列に実体化する。
--
-- ブランド名は別テーブルにあるため生成列にできない。毎回 join して連結すると
-- 全行スキャンになり trgm インデックスも効かないので、トリガで維持する。
alter table perfumes add column search_text text not null default '';

comment on column perfumes.search_text is
  'ブランド名と製品名の全表記を小文字で連結したもの。トリガで維持する。直接更新しない。';

create function build_search_text(p perfumes, b brands) returns text
language sql immutable
as $$
  select lower(concat_ws(' ',
    b.name_en, b.name_ja, b.name_original, array_to_string(b.synonyms, ' '),
    p.name_en, p.name_ja, p.name_original, array_to_string(p.synonyms, ' ')))
$$;

create function refresh_perfume_search_text() returns trigger
language plpgsql as $$
declare b brands%rowtype;
begin
  select * into b from brands where id = new.brand_id;
  new.search_text := build_search_text(new, b);
  return new;
end;
$$;

create trigger perfumes_search_text
  before insert or update of brand_id, name_en, name_ja, name_original, synonyms
  on perfumes
  for each row execute function refresh_perfume_search_text();

-- ブランド名が変わったら、その配下の香水をすべて作り直す。
create function refresh_brand_perfume_search_text() returns trigger
language plpgsql as $$
begin
  update perfumes set search_text = build_search_text(perfumes, new)
  where brand_id = new.id;
  return new;
end;
$$;

create trigger brands_search_text
  after update of name_en, name_ja, name_original, synonyms on brands
  for each row execute function refresh_brand_perfume_search_text();

-- 既存行の埋め直し。この時点では空だが、順序を明示しておく。
update perfumes p set search_text = build_search_text(p, b)
from brands b where b.id = p.brand_id;

create index perfumes_search_text_trgm
  on perfumes using gin (search_text gin_trgm_ops);


create type perfume_search_result as (
  id             uuid,
  slug           text,
  name_en        text,
  name_ja        text,
  brand_id       uuid,
  brand_name_en  text,
  brand_name_ja  text,
  concentration  concentration,
  gender_target  gender_target,
  release_year   smallint,
  image_url      text,
  is_verified    boolean,
  score          real
);

create function search_perfumes(
  q                  text default null,
  brand_ids          uuid[] default null,
  note_ids           uuid[] default null,
  accord_ids         uuid[] default null,
  concentrations     concentration[] default null,
  genders            gender_target[] default null,
  year_from          smallint default null,
  year_to            smallint default null,
  include_unverified boolean default true,
  max_results        integer default 30,
  skip               integer default 0,
  fuzzy_threshold    real default 0.6
) returns setof perfume_search_result
language sql stable
as $$
  with normalized as (
    select nullif(lower(trim(q)), '') as needle
  ),
  scored as (
    select
      p, b,
      case
        when n.needle is null then 0::real
        -- 部分文字列として含まれていれば最上位。類似度より信頼できる。
        when p.search_text like '%' || n.needle || '%' then 1.0::real
        else word_similarity(n.needle, p.search_text)
      end as score
    from perfumes p
    join brands b on b.id = p.brand_id
    cross join normalized n
    where (include_unverified or p.is_verified)
      and (brand_ids is null or p.brand_id = any (brand_ids))
      and (concentrations is null or p.concentration = any (concentrations))
      and (genders is null or p.gender_target = any (genders))
      and (year_from is null or p.release_year >= year_from)
      and (year_to is null or p.release_year <= year_to)
      -- 指定した香料をすべて含むもの
      and (note_ids is null or not exists (
            select 1 from unnest(note_ids) as want (note_id)
            where not exists (
              select 1 from perfume_notes pn
              where pn.perfume_id = p.id and pn.note_id = want.note_id)))
      -- 指定した香調をすべて含むもの
      and (accord_ids is null or not exists (
            select 1 from unnest(accord_ids) as want (accord_id)
            where not exists (
              select 1 from perfume_accords pa
              where pa.perfume_id = p.id and pa.accord_id = want.accord_id)))
      -- 語単位の類似度を使う。文字列全体の similarity では、
      -- 長い製品名ほど分母が大きくなって当たらなくなる。
      and (n.needle is null
           or p.search_text like '%' || n.needle || '%'
           or word_similarity(n.needle, p.search_text) >= fuzzy_threshold)
  )
  select
    (s.p).id, (s.p).slug, (s.p).name_en, (s.p).name_ja,
    (s.b).id, (s.b).name_en, (s.b).name_ja,
    (s.p).concentration, (s.p).gender_target, (s.p).release_year,
    (s.p).image_url, (s.p).is_verified,
    s.score
  from scored s
  -- 検証済みを優先し、その中でスコア順。同点は新しいものから。
  order by (s.p).is_verified desc, s.score desc,
           (s.p).release_year desc nulls last, (s.p).name_en
  limit greatest(1, least(max_results, 100))
  offset greatest(0, skip);
$$;

comment on function search_perfumes is
  '検証済みを常に優先する。未検証データが検索結果の上位を占めるのを防ぐため。';


-- 香水詳細で使うノートピラミッド。段と記載順で並べる。
-- 戻り値の列名に position は使えない（SQL の予約語で position(x in y) と衝突する）。
create function perfume_note_pyramid(target uuid)
returns table (
  pyramid_position note_position,
  position_order   smallint,
  note_id          uuid,
  slug             text,
  name_en          text,
  name_ja          text,
  family           text
)
language sql stable
as $$
  select pn.position, pn.position_order, n.id, n.slug, n.name_en, n.name_ja, n.family
  from perfume_notes pn
  join notes n on n.id = pn.note_id
  where pn.perfume_id = target
  order by
    case pn.position
      when 'top' then 1 when 'middle' then 2 when 'base' then 3 else 4
    end,
    pn.position_order;
$$;

-- 香水詳細の香調バー。構成比の大きい順。
create function perfume_accord_bars(target uuid)
returns table (
  accord_id uuid,
  slug      text,
  name_en   text,
  name_ja   text,
  strength  numeric
)
language sql stable
as $$
  select a.id, a.slug, a.name_en, a.name_ja, pa.strength
  from perfume_accords pa
  join accords a on a.id = pa.accord_id
  where pa.perfume_id = target
  order by pa.strength desc, a.sort_order;
$$;
