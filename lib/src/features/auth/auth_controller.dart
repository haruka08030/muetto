import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';

/// 現在のセッション。未ログインなら null。
///
/// 起動直後はセッション復元中のため loading になる。
/// ルーターはこの loading を見てリダイレクト判断を保留する。
final authStateProvider = StreamProvider<Session?>((ref) {
  return supabase.auth.onAuthStateChange.map((event) => event.session);
});

/// ゲストとして閲覧中か。
///
/// 開発用の GUEST_MODE が有効なときだけ true になりうる。
/// 無効時は常に false のままなので、リリースビルドの導線は変わらない。
final guestModeProvider = NotifierProvider<GuestModeController, bool>(
  GuestModeController.new,
);

class GuestModeController extends Notifier<bool> {
  @override
  bool build() => false;

  void enter() {
    if (!Env.guestModeEnabled) return;
    state = true;
  }

  void exit() => state = false;
}

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
    // ゲスト閲覧も同時に解除する。解除しないとサインイン画面に戻れない。
    ref.read(guestModeProvider.notifier).exit();
    state = await AsyncValue.guard(() => supabase.auth.signOut());
  }
}
