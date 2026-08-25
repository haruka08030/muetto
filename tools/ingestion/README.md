# 取り込みパイプライン

香水マスタ（ブランド・香水・香料・香調）を組み立てるツール群。
アプリ本体とは独立して動かす。Python 3.11+ のみで、外部依存は無い。

## 使い方

```bash
cd tools/ingestion

python -m ingestion.build_masters   # 香料・香調マスタを生成
python -m ingestion.emit_seed       # Supabase 用のシード SQL を出力

python -m pytest tests/ -q          # 正規化ロジックのテスト
```

生成物は `data/` に出力され、リポジトリにコミットする。
一次データを毎回取得しなくても、マスタの中身をレビューできるようにするため。

| ファイル | 内容 |
|---|---|
| `data/notes_master.csv` | 香料マスタ（正規形・系統・日本語名） |
| `data/note_aliases.csv` | 別名 → 正規形の対応表 |
| `data/accords_master.csv` | 香調アコードの固定リスト |
| `data/unmapped_notes.csv` | しきい値未満で採用しなかった語（人手レビュー用） |
| `../../supabase/seed/0001_notes_accords.sql` | 上記から生成したシード |

## 現在の一次ソース

香料語彙・香調語彙の初版は、Parfumo 由来のオープンデータセット
（TidyTuesday 2024-12-10 経由で配布されているもの）から作った。
香水 59,325 件・ブランド 1,452 件を含む。

このリポジトリにコミットするのは **正規化・翻訳・分類を経た語彙のみ**で、
香水レコードそのものは再配布しない。必要なときに `ingestion.fetch` で取得する。

## 正規化の考え方

一次ソースの香料名には産地違い・抽出法違いの表記が大量に含まれる。

```
Bulgarian rose / Turkish rose absolute / Grasse rose / Rose otto / Moroccan rose absolute
```

これらをそのままマスタに載せると、好み分析の特徴量が「ローズ」という 1 つの概念に対して
十数個へ分散し、サンプル件数が確保できなくなる。
そこで修飾語を剥がした**正規形**を求め、元の表記は**別名**として保持する。

- 産地の修飾語（Bulgarian, Sicilian, Madagascan …）を先頭から剥がす
- 抽出法の修飾語（absolute, CO2, oil, otto …）を末尾から剥がす
- 剥がすと別物になる語（`orange blossom` → `orange`）は保護リストで守る
- 学名・別称（`Jasminum grandiflorum` → jasmine、`Agarwood` → oud）は手動辞書で寄せる

結果として、ユニーク 3,998 語 → 正規形 497 語（出現の 97.1% をカバー）に畳んでいる。

## 一次ソースに混入している実在しない香料名

このデータセットには、**実在しない香料名が約 3.2% のレコードに 1 語ずつ混入している**。

```
Flibtix / Zarquon / Snorplax / XylophazQ / Blimfark / Quintozar ...
```

Avon や 4711 といった一般ブランドの、それ以外は正常なレコードに紛れ込んでおり、
無断再配布を検知するためのカナリア（透かし）と見られる。
悪臭を表す語（`Stench`, `Putrescence`, `Sewage` など、出現数 50〜85 の帯に集中）も
同じ注入群と判断した。

放置すると香料マスタに実在しない語が載って分析の特徴量が汚れるうえ、
透かしを含んだままのデータを配布することにもなる。

`ingestion/blocklist.py` で除外している。検出は以下の手順で行った。

1. 明らかな造語を目視で数十語拾い、種（seed）とする
2. 種を含むレコードとの共起率（lift）を全語について計算する
3. lift が基準率の 2.5 倍以上の語を候補として抽出（111 語）
4. 候補を人手でレビューし、実在する香料（`cade juniper`, `boronia`, `patchouli absolute` など）
   を戻したうえで確定させる

前衛的な香水で実際に使われる語（`smoke`, `tar`, `ash`, `rubber`, `asphalt` など）は
判断を保留し、マスタには載せたうえで `needs_review` フラグを立てている。

**別のソースを追加するときも、同種の混入を必ず疑うこと。**

## 新しいソースを足すとき

`ingestion/fetch.py` にアダプタを足し、`ingestion/normalize.py` の
正規形へ寄せる。パーサをソースごとに分離しておくことで、
特定のソースが使えなくなっても切り離せるようにする（docs/data-ingestion.md 2）。

スクレイピングを行う場合は、robots.txt の尊重・レート制限（1 ドメイン 1 req / 2 秒）・
識別可能な User-Agent・事実データのみの取得・出典の保持を必ず守ること。
