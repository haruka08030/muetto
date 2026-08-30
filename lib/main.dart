import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/core/env.dart';
import 'src/core/supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env は任意。未配置でも --dart-define だけで起動できるようにする。
  try {
    await dotenv.load();
  } catch (_) {
    // 読めなければ --dart-define にフォールバックする。
    // 値が本当に無い場合は下の isValid で検出される。
  }

  final config = Env.resolve();
  if (!config.isValid) {
    runApp(MisconfiguredApp(message: config.validationMessage));
    return;
  }

  await initSupabase(config);
  runApp(const ProviderScope(child: PerfumeApp()));
}
