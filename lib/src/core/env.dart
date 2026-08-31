import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 実行時設定。`--dart-define` または `.env` から読む。
///
/// クライアントに置いてよいのは公開鍵（publishable key / 旧 anon key）のみ。
/// service_role key は RLS を迂回するため、アプリに含めてはならない。
/// `.env` はアセットとしてアプリバンドルに同梱される点に注意。
class Env {
  const Env({required this.supabaseUrl, required this.supabasePublishableKey});

  /// サインイン画面を通らずに匿名で始められるようにするか。
  ///
  /// `--dart-define=GUEST_MODE=true` でのみ有効。既定は false なので
  /// リリースビルドの導線は変わらない。
  ///
  /// 匿名サインインは Supabase 側の実際のセッションを作る。`auth.uid()`
  /// が実在するので RLS は通常どおり効き、ログもコレクションも本番と
  /// 同じ経路で動く。以前は UI だけ開けていたが、それでは RLS で弾かれ、
  /// 開発中の確認にならなかった。
  static const bool guestModeEnabled = bool.fromEnvironment('GUEST_MODE');

  /// `--dart-define` を優先し、未指定の項目のみ `.env` で補う。
  ///
  /// CI やリリースビルドでは `.env` を置かずに `--dart-define` だけで
  /// 完結させられる。ローカル開発では `.env` に置いたままで動く。
  factory Env.resolve() => Env(
    supabaseUrl: _read('SUPABASE_URL', _dartDefineUrl),
    supabasePublishableKey: _read('SUPABASE_PUBLISHABLE_KEY', _dartDefineKey),
  );

  static const String _dartDefineUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _dartDefineKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// `--dart-define` の値があればそれを、なければ `.env` の値を返す。
  ///
  /// `.env` の読み込みに失敗している場合（ファイル未配置など）は
  /// 例外にせず空文字を返し、`validationMessage` 側で案内する。
  static String _read(String name, String fromDartDefine) {
    if (fromDartDefine.isNotEmpty) return fromDartDefine;
    if (!dotenv.isInitialized) return '';
    return dotenv.maybeGet(name) ?? '';
  }

  final String supabaseUrl;

  /// 公開鍵。Supabase の新しい `sb_publishable_...` 形式と、
  /// 従来の anon key のどちらも受け付ける。
  final String supabasePublishableKey;

  bool get isValid =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  String get validationMessage {
    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabasePublishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
    ];
    return '${missing.join(' と ')} が設定されていません。'
        '.env.example を参照して .env に置くか、'
        '--dart-define で渡してください。';
  }
}
