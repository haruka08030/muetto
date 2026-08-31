import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/features/collection/add_actions.dart';
import 'package:muetto/src/models/perfume.dart';

/// 香水詳細が追加の入口になる。三つは意味が違うので、
/// 並んでいても取り違えないことを確かめる。
void main() {
  testWidgets('試した・持ってる・欲しいが並ぶ', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AddToCollectionActions(perfume: _perfume())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('試した'), findsOneWidget);
    expect(find.text('持ってる'), findsOneWidget);
    expect(find.text('欲しい'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('試したは他の二つより強調する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AddToCollectionActions(perfume: _perfume())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 記録が主目的なので、試したは塗り、残り二つは枠線にする。
    expect(find.widgetWithText(FilledButton, '試した'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '持ってる'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '欲しい'), findsOneWidget);
  });

  testWidgets('欲しいを押すと優先度を尋ねる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AddToCollectionActions(perfume: _perfume())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('欲しい'));
    await tester.pumpAndSettle();

    expect(find.text('どれくらい欲しい？'), findsOneWidget);
    expect(find.text('とても欲しい'), findsOneWidget);
  });
}

PerfumeSummary _perfume() => PerfumeSummary.fromJson({
  'id': 'p1',
  'name_en': 'Yuzu no Asa',
  'name_ja': '柚子の朝',
  'brand_name_en': 'Maison Hikari',
  'brand_name_ja': 'メゾン・ヒカリ',
  'concentration': 'edt',
  'is_verified': true,
});
