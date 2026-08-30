import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/features/log/log_form_screen.dart';
import 'package:muetto/src/models/perfume.dart';
import 'package:muetto/src/models/tasting_log.dart';

void main() {
  Future<void> pumpForm(WidgetTester tester, {TastingLog? existing}) async {
    // フォームは ListView なので、画面が低いと下の項目が作られない。
    // 実機の縦長に近い高さを与えて、全体を評価できるようにする。
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: LogFormScreen(perfume: _perfume(), existing: existing),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('新規は空で開き、評価を入れるまで保存できない', (tester) async {
    await pumpForm(tester);

    expect(find.text('試香ログ'), findsOneWidget);
    expect(find.text('星をタップして評価'), findsOneWidget);

    expect(find.text('保存する'), findsOneWidget);

    // 評価が無いうちは押せない。
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('編集は既存の値を埋めて開く', (tester) async {
    await pumpForm(
      tester,
      existing: TastingLog.fromJson({
        'id': 'l1',
        'perfume_id': 'p1',
        'rating': 4.2,
        'memo': '朝つけたい',
        'method': 'skin',
        'want_to_buy': true,
        'tested_at': '2026-08-30',
      }),
    );

    expect(find.text('ログを編集'), findsOneWidget);
    expect(find.text('更新する'), findsOneWidget);
    // 評価・メモ・方法・買いたいが復元されている。
    expect(find.text('4.2'), findsOneWidget);
    expect(find.text('朝つけたい'), findsOneWidget);

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '肌につけた'),
    );
    expect(chip.selected, isTrue);

    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未知の method が来ても落ちない', (tester) async {
    // DB に enum が増えた場合でも編集画面を開けるようにする。
    await pumpForm(
      tester,
      existing: TastingLog.fromJson({
        'id': 'l1',
        'perfume_id': 'p1',
        'rating': 3,
        'method': 'unknown_method',
        'tested_at': '2026-08-30',
      }),
    );

    expect(find.text('ログを編集'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
