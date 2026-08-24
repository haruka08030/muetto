import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

Future<void> initSupabase(Env config) async {
  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
