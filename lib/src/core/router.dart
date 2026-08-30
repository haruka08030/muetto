import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/home/home_screen.dart';
import '../features/perfume/perfume_detail_screen.dart';
import '../features/search/search_screen.dart';

/// 画面 ID。パス文字列を直接書かないための定数。
abstract final class Routes {
  static const signIn = '/sign-in';
  static const home = '/';
  static const search = '/search';
  static const perfume = '/perfume';
}

final routerProvider = Provider<GoRouter>((ref) {
  // 認証状態が変わったらルーターに再評価させる。
  final authState = ref.watch(authStateProvider);
  // ゲスト閲覧の開始・終了でも再評価させる。
  final isGuest = ref.watch(guestModeProvider);

  return GoRouter(
    initialLocation: Routes.home,
    redirect: (context, state) {
      // 認証状態の取得中はリダイレクトを保留する。
      if (authState.isLoading) {
        return null;
      }
      // ゲストはログイン済みと同じ扱いで通す。
      // 書き込みが要る機能は RLS 側で弾かれる。
      final canBrowse = authState.value != null || isGuest;
      final atSignIn = state.matchedLocation == Routes.signIn;

      if (!canBrowse && !atSignIn) {
        return Routes.signIn;
      }
      if (canBrowse && atSignIn) {
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
      GoRoute(
        path: Routes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '${Routes.perfume}/:id',
        builder: (context, state) =>
            PerfumeDetailScreen(perfumeId: state.pathParameters['id']!),
      ),
    ],
  );
});
