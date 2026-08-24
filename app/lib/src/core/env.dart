/// 実行時設定。`--dart-define` で注入する。
///
/// クライアントに置いてよいのは anon key のみ。
/// service_role key は RLS を迂回するため、アプリに含めてはならない。
class Env {
  const Env({required this.supabaseUrl, required this.supabaseAnonKey});

  factory Env.fromDartDefine() => const Env(
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      );

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isValid => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  String get validationMessage {
    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
    ];
    return '${missing.join(' と ')} が設定されていません。'
        'app/.env.example を参照して --dart-define で渡してください。';
  }
}
