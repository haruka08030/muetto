import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase.dart';

/// 現在のセッション。未ログインなら null。
///
/// 起動直後はセッション復元中のため loading になる。
/// ルーターはこの loading を見てリダイレクト判断を保留する。
final authStateProvider = StreamProvider<Session?>((ref) {
  return supabase.auth.onAuthStateChange.map((event) => event.session);
});

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => supabase.auth.signInWithPassword(email: email, password: password),
    );
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => supabase.auth.signUp(email: email, password: password),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => supabase.auth.signOut());
  }
}
