# 香水管理アプリ（プロダクト名未定）

試香の記憶をデジタル化し、蓄積した評価から「自分の好きな香料・苦手な香料」を客観化して、
次の1本の失敗を防ぐパーソナル香水管理アプリ。

> ワインにおける Vivino のポジションを、香水で実現することを目指す。

※ プロダクト名は未定。ドキュメント中では「本アプリ」と表記する。

## ステータス

**要件定義フェーズ**。実装はまだ開始していない。

## ドキュメント

| ドキュメント | 内容 |
|---|---|
| [docs/requirements.md](docs/requirements.md) | 要件定義書（コア。機能要件・非機能要件・スコープ） |
| [docs/screens.md](docs/screens.md) | 画面一覧と主要導線 |
| [docs/data-model.md](docs/data-model.md) | データモデル・DBスキーマ・RLS方針 |
| [docs/preference-algorithm.md](docs/preference-algorithm.md) | 好み分析・レコメンドのアルゴリズム仕様 |
| [docs/data-ingestion.md](docs/data-ingestion.md) | 香水マスタDBの構築・運用方針 |
| [docs/roadmap.md](docs/roadmap.md) | 開発フェーズとマイルストーン |
| [docs/decisions.md](docs/decisions.md) | 意思決定ログ（ADR） |

## 技術スタック

- **モバイル**: Flutter（iOS / Android）
- **バックエンド**: Supabase（PostgreSQL / Auth / Storage / Edge Functions）
- **OCR**: Google ML Kit（オンデバイス・テキスト認識）

## リポジトリ履歴について

このリポジトリは元々 `x-to-notion`（X→Notion 保存 Chrome 拡張）だった。
本プロジェクトの開始にあたり既存コードはすべて削除している。
