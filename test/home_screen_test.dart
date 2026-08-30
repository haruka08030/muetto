import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/features/home/home_screen.dart';
import 'package:muetto/src/features/log/log_list_controller.dart';
import 'package:muetto/src/models/tasting_log.dart';

/// ホームは認証状態で出すものが変わる。
/// ゲストは記録を読めないので、代わりに何ができるかを伝える。
void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    required List<TastingLogWithPerfume> logs,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [recentLogsProvider.overrideWith((ref) async => logs)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('記録が無ければ書き方を案内する', (tester) async {
    await pumpHome(tester, logs: const []);

    expect(find.textContaining('まだ記録がありません'), findsOneWidget);
    // 空のときに「すべて見る」を出しても行き先が空。
    expect(find.text('すべて見る'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('記録があれば香水名と評価を出す', (tester) async {
    await pumpHome(tester, logs: [_item()]);

    expect(find.text('柚子の朝'), findsOneWidget);
    expect(find.text('メゾン・ヒカリ'), findsOneWidget);
    expect(find.text('4.2'), findsOneWidget);
    expect(find.text('すべて見る'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

TastingLogWithPerfume _item() => TastingLogWithPerfume.fromJson({
  'id': 'l1',
  'perfume_id': 'p1',
  'rating': 4.2,
  'tested_at': '2026-08-30',
  'perfumes': {
    'id': 'p1',
    'name_en': 'Yuzu no Asa',
    'name_ja': '柚子の朝',
    'concentration': 'edt',
    'is_verified': true,
    'brands': {'name_en': 'Maison Hikari', 'name_ja': 'メゾン・ヒカリ'},
  },
});
