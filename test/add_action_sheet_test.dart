import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/features/log/add_action_sheet.dart';

void main() {
  Future<AddAction?> openSheet(WidgetTester tester, {String? tapLabel}) async {
    AddAction? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showAddActionSheet(context, '柚子の朝');
              },
              child: const Text('開く'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    if (tapLabel != null) {
      await tester.tap(find.text(tapLabel));
      await tester.pumpAndSettle();
    }
    return result;
  }

  testWidgets('三つの選択肢と香水名が出る', (tester) async {
    await openSheet(tester);

    expect(find.text('柚子の朝'), findsOneWidget);
    expect(find.text('試した'), findsOneWidget);
    expect(find.text('持ってる'), findsOneWidget);
    expect(find.text('欲しい'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('選んだ結果が返る', (tester) async {
    expect(await openSheet(tester, tapLabel: '試した'), AddAction.tasted);
  });

  testWidgets('持ってるを選べる', (tester) async {
    expect(await openSheet(tester, tapLabel: '持ってる'), AddAction.owned);
  });

  testWidgets('欲しいを選べる', (tester) async {
    expect(await openSheet(tester, tapLabel: '欲しい'), AddAction.wanted);
  });
}
