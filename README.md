# X to Notion Saver 🚀
X（Twitter）のブックマークやポストを、Chrome拡張機能からワンクリックでNotionデータベースへ保存するツールです。

## プロジェクト概要

このプロジェクトは、X（旧Twitter）のブックマークやタイムライン上のツイートを、ワンクリックでNotionデータベースに保存するシステムです。

## アーキテクチャ

1.  **Frontend**: Chrome Extension (JavaScript)
    *   XのDOMからツイート内容、投稿者、URL、画像を取得し、Supabase Edge Functionsへ送信します。
2.  **Backend**: Supabase Edge Functions (TypeScript / Deno)
    *   拡張機能からのリクエストを受け取り、Notion APIを介してデータを整形・保存します。
3.  **Database**: Notion Database
    *   保存されたツイートを構造化データとして蓄積します。

## セットアップ

このプロジェクトをセットアップするには、以下の手順を実行する必要があります。

### 1. Supabaseプロジェクトのセットアップ

*   Supabaseアカウントを作成し、新しいプロジェクトを作成します。
*   SupabaseプロジェクトでEdge Functionsを有効にします。

### 2. Notionデータベースのセットアップ

*   Notionワークスペースに新しいデータベースを作成します。
*   データベースには、以下のプロパティが必要です（例）：
    *   `Title` (タイトル) - テキスト
    *   `URL` (URL) - URL
    *   `Author` (著者) - テキスト
    *   `Content` (内容) - テキスト
    *   `Media` (メディア) - ファイル＆メディア (オプション)
*   Notion APIインテグレーションを作成し、データベースへのアクセスを許可します。
*   インテグレーションのAPIキーを控えておきます。

### 3. Edge Functionの設定

*   `supabase/functions/save-to-notion/index.ts` を編集し、環境変数 `NOTION_API_KEY` と `NOTION_DATABASE_ID` を設定します。
*   Supabase CLIを使用してEdge Functionをデプロイします。

### 4. Chrome拡張機能のセットアップ

*   `extension/manifest.json` を編集し、バックエンドのEdge FunctionのURLを指すように設定します。
*   Chromeブラウザに拡張機能をサイドロードします。

## 使用方法

1.  X（Twitter）のページにアクセスします。
2.  保存したいツイートの近くにある拡張機能のアイコンをクリックします。
3.  ツイートの内容がNotionデータベースに保存されます。

## トラブルシューティング

### VS CodeでのTypeScriptエラー (Deno)

VS CodeがDeno固有の構文（URLインポートやDenoオブジェクト）を認識できない場合、Deno拡張機能が正しく設定されているか確認してください。

*   **Deno VS Code拡張機能をインストールする**: 拡張機能マーケットプレイスから「Deno」を検索してインストールします。
*   **VS Codeのワークスペース設定**: `.vscode/settings.json` に以下を追加して、Denoの言語サービスを有効にします。

    ```json
    {
      "deno.enable": true,
      "deno.lint": true,
      "deno.unstable": true
    }
    ```

これにより、`req: Request` の型エラーや `catch` ブロックでの `error: unknown` の問題が解消され、Denoのインポートパスが正しく解決されるようになります。