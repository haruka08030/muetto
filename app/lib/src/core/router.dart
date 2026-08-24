import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/home/home_screen.dart';

/// 画面 ID。パス文字列を直接書かないための定数。
abstract final class Routes {
  static const signIn = '/sign-in';
  static const home = '/';
}

final routerProvider = Provider<GoRouter>((ref) {
  // 認証状態が変わったらルーターに再評価させる。
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.home,
    redirect: (context, state) {
      // 認証状態の取得中はリダイレクトを保留する。
      if (authState.isLoading) {
        return null;
      }
      final signedIn = authState.value != null;
      final atSignIn = state.matchedLocation == Routes.signIn;

      if (!signedIn && !atSignIn) {
        return Routes.signIn;
      }
      if (signedIn && atSignIn) {
        return Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});
