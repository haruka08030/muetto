import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/core/env.dart';
import 'src/core/supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = Env.fromDartDefine();
  if (!config.isValid) {
    runApp(MisconfiguredApp(message: config.validationMessage));
    return;
  }

  await initSupabase(config);
  runApp(const ProviderScope(child: PerfumeApp()));
}
