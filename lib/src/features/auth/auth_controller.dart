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

/// 匿名で始めているか。
///
/// 匿名サインインでも実際のセッションができるので、[authStateProvider]
/// だけではログイン済みと区別が付かない。表示を変えるためにここで覚える。
final isAnonymousProvider = Provider<bool>((ref) {
  final session = ref.watch(authStateProvider).value;
  return session?.user.isAnonymous ?? false;
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

  /// 匿名で始める。開発中に全機能を触るための入口。
  ///
  /// 実際のセッションを作るので、ログもコレクションも本番と同じ経路で
  /// 動く。GUEST_MODE が無効なら何もしない。
  Future<void> signInAnonymously() async {
    if (!Env.guestModeEnabled) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => supabase.auth.signInAnonymously());
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => supabase.auth.signOut());
  }
}
