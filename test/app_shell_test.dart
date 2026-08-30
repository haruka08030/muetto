import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:muetto/src/features/placeholder/coming_soon_screen.dart';
import 'package:muetto/src/features/shell/app_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AppShell をタブだけ差し替えて描画する。
///
/// 本物のルーターは認証状態を見るため、テストからは組み立てにくい。
/// ここで見たいのは外枠（ラベルが出るか、収まるか、切り替わるか）なので、
/// 枝はダミーにして AppShell だけを対象にする。
void main() {
  testWidgets('タブが5つ分の導線を持ち、ラベルが出る', (tester) async {
    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (c, s, shell) => AppShell(navigationShell: shell),
          branches: [
            for (final p in ['/a', '/b', '/c', '/d', '/e'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: p,
                    builder: (c, s) => ComingSoonScreen(
                      title: 'T$p',
                      phase: 2,
                      description: 'desc',
                      icon: Icons.abc,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    // 4 つのラベルと中央 FAB。
    expect(find.text('ホーム'), findsOneWidget);
    expect(find.text('検索'), findsOneWidget);
    expect(find.text('コレクション'), findsOneWidget);
    expect(find.text('分析'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // オーバーフローが出ていないこと（例外が飛べばテストが落ちる）。
    expect(tester.takeException(), isNull);

    // 検索タブへ切り替わる。
    await tester.tap(find.text('検索'));
    await tester.pumpAndSettle();
    expect(find.text('T/b'), findsOneWidget);
  });
}
