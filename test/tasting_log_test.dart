import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/models/tasting_log.dart';

void main() {
  group('TastingLog.fromJson', () {
    test('numeric の rating が数値で返っても文字列で返っても読める', () {
      // PostgREST は numeric を文字列で返すことがある。
      final asNumber = TastingLog.fromJson(_row(rating: 4.3));
      final asString = TastingLog.fromJson(_row(rating: '4.3'));

      expect(asNumber.rating, 4.3);
      expect(asString.rating, 4.3);
    });

    test('任意項目が無くても落ちない', () {
      final log = TastingLog.fromJson({
        'id': 'l1',
        'perfume_id': 'p1',
        'rating': 3,
        'tested_at': '2026-08-30',
      });

      expect(log.memo, isNull);
    });
  });
}

Map<String, dynamic> _row({required Object rating}) => {
  'id': 'l1',
  'perfume_id': 'p1',
  'rating': rating,
  'tested_at': '2026-08-30',
};
