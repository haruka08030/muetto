import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/home/home_screen.dart';
import '../features/perfume/perfume_detail_screen.dart';
import '../features/collection/collection_screen.dart';
import '../features/log/pick_perfume_screen.dart';
import '../features/placeholder/coming_soon_screen.dart';
import '../features/search/search_screen.dart';
import '../features/shell/app_shell.dart';

/// 画面 ID。パス文字列を直接書かないための定数。
abstract final class Routes {
  static const signIn = '/sign-in';
  static const home = '/';
  static const search = '/search';
  static const log = '/log';
  static const collection = '/collection';
  static const analysis = '/analysis';

  /// 香水詳細。タブの中に積むので、各タブの配下に同じ形で生える。
  static const perfume = 'perfume';

  /// 香水詳細へのパスを、今いるタブの下に作る。
  static String perfumeUnder(String tab, String id) =>
      tab == home ? '/$perfume/$id' : '$tab/$perfume/$id';
}

/// タブの並び順。StatefulShellRoute の branches と同じ順にする。
/// 番号を直接書かず、ここを見て参照する。
abstract final class Tabs {
  static const home = 0;
  static const search = 1;
  static const log = 2;
  static const collection = 3;
  static const analysis = 4;
}

/// タブごとのナビゲーションキー。タブが履歴を保つために要る。
final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // 認証状態が変わったらルーターに再評価させる。
  final authState = ref.watch(authStateProvider);
  // ゲスト閲覧の開始・終了でも再評価させる。
  final isGuest = ref.watch(guestModeProvider);

  return GoRouter(
    navigatorKey: _rootKey,
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          _branch(Routes.home, (context, state) => const HomeScreen()),
          _branch(Routes.search, (context, state) => const SearchScreen()),
          _branch(
            Routes.log,
            (context, state) => const PickPerfumeScreen(),
          ),
          _branch(
            Routes.collection,
            (context, state) => const CollectionScreen(),
          ),
          _branch(
            Routes.analysis,
            (context, state) => const ComingSoonScreen(
              title: '分析',
              phase: 3,
              description: 'ログが溜まると、好きな香料と香調の傾向が見えてきます。',
              icon: Icons.insights_outlined,
            ),
          ),
        ],
      ),
    ],
  );
});

/// タブ 1 つぶんの枝。香水詳細はどのタブからでも開けるよう、
/// 各枝の配下に同じ形で生やす。全画面で覆わずタブの中に積むので、
/// どのタブから来たのかが保たれる（docs/screens.md 2）。
StatefulShellBranch _branch(String path, GoRouterWidgetBuilder builder) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        builder: builder,
        routes: [
          GoRoute(
            path: '${Routes.perfume}/:id',
            builder: (context, state) =>
                PerfumeDetailScreen(perfumeId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
}
