import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/features/log/rating_stars.dart';

/// ADR-004: タップで整数、そのままドラッグで 0.1 刻み。
void main() {
  Future<void> pumpStars(
    WidgetTester tester, {
    required ValueChanged<double> onChanged,
    double rating = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RatingStars(rating: rating, onChanged: onChanged),
          ),
        ),
      ),
    );
  }

  testWidgets('タップすると整数が入る', (tester) async {
    final values = <double>[];
    await pumpStars(tester, onChanged: values.add);

    final stars = tester.getRect(find.byType(RatingStars));
    // 3 つ目の星の中ほどを押す。
    await tester.tapAt(Offset(stars.left + stars.width * 0.5, stars.center.dy));
    await tester.pump();

    expect(values, isNotEmpty);
    expect(values.last, 3.0, reason: '中央付近のタップは 3 になる');
    expect(values.last % 1, 0, reason: 'タップは整数だけを返す');
  });

  testWidgets('左端をタップしても 0 にはならず 1 が下限', (tester) async {
    final values = <double>[];
    await pumpStars(tester, onChanged: values.add);

    final stars = tester.getRect(find.byType(RatingStars));
    await tester.tapAt(Offset(stars.left + 1, stars.center.dy));
    await tester.pump();

    expect(values.last, 1.0);
  });

  testWidgets('ドラッグすると 0.1 刻みになる', (tester) async {
    final values = <double>[];
    await pumpStars(tester, onChanged: values.add);

    final stars = tester.getRect(find.byType(RatingStars));
    // 左端から 70% の位置まで引く。
    final gesture = await tester.startGesture(
      Offset(stars.left + 1, stars.center.dy),
    );
    await gesture.moveTo(
      Offset(stars.left + stars.width * 0.7, stars.center.dy),
    );
    await gesture.up();
    await tester.pump();

    expect(values.last, closeTo(3.5, 0.11), reason: '5 星の 70% は 3.5 前後');
    // 0.1 刻みに丸められている（浮動小数の誤差を考慮して 1 桁で見る）。
    final rounded = (values.last * 10).round() / 10;
    expect(values.last, closeTo(rounded, 0.001));
  });

  testWidgets('右端を越えても 5.0 を超えない', (tester) async {
    final values = <double>[];
    await pumpStars(tester, onChanged: values.add);

    final stars = tester.getRect(find.byType(RatingStars));
    final gesture = await tester.startGesture(stars.center);
    await gesture.moveTo(Offset(stars.right + 200, stars.center.dy));
    await gesture.up();
    await tester.pump();

    expect(values.last, 5.0);
  });
}
