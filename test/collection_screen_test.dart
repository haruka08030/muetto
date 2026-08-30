import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/features/collection/collection_screen.dart';
import 'package:muetto/src/features/log/log_list_controller.dart';
import 'package:muetto/src/models/tasting_log.dart';

void main() {
  testWidgets('内タブが 3 つ並び、ログが空なら書き方を案内する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // ネットワークに出ないよう、空のログを差し込む。
          logListProvider.overrideWith(
            (ref) async => const <TastingLogWithPerfume>[],
          ),
        ],
        child: const MaterialApp(home: CollectionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ログ'), findsOneWidget);
    expect(find.text('所持品'), findsOneWidget);
    expect(find.text('欲しいもの'), findsOneWidget);
    expect(find.textContaining('まだログがありません'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ログがあれば香水名と評価が出る', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logListProvider.overrideWith(
            (ref) async => [
              TastingLogWithPerfume.fromJson({
                'id': 'l1',
                'perfume_id': 'p1',
                'rating': 4.2,
                'tested_at': '2026-08-30',
                'memo': 'よかった',
                'perfumes': {
                  'id': 'p1',
                  'name_en': 'Yuzu no Asa',
                  'name_ja': '柚子の朝',
                  'concentration': 'edt',
                  'is_verified': true,
                  'brands': {'name_en': 'Maison Hikari', 'name_ja': 'メゾン・ヒカリ'},
                },
              }),
            ],
          ),
        ],
        child: const MaterialApp(home: CollectionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('柚子の朝'), findsOneWidget);
    expect(find.text('メゾン・ヒカリ'), findsOneWidget);
    expect(find.text('4.2'), findsOneWidget);
    expect(find.text('よかった'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
