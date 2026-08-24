/// 実行時設定。`--dart-define` で注入する。
///
/// クライアントに置いてよいのは公開鍵（publishable key / 旧 anon key）のみ。
/// service_role key は RLS を迂回するため、アプリに含めてはならない。
class Env {
  const Env({required this.supabaseUrl, required this.supabasePublishableKey});

  factory Env.fromDartDefine() => const Env(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

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
        'app/.env.example を参照して --dart-define で渡してください。';
  }
}
