import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/models/tasting_log.dart';

void main() {
  group('TastingLogWithPerfume.fromJson', () {
    test('結合した香水とブランドを読める', () {
      final item = TastingLogWithPerfume.fromJson({
        'id': 'l1',
        'perfume_id': 'p1',
        'rating': 4.2,
        'tested_at': '2026-08-30',
        'memo': 'よかった',
        'want_to_buy': true,
        'perfumes': {
          'id': 'p1',
          'name_en': 'Yuzu no Asa',
          'name_ja': '柚子の朝',
          'concentration': 'edt',
          'is_verified': true,
          'brands': {'name_en': 'Maison Hikari', 'name_ja': 'メゾン・ヒカリ'},
        },
      });

      expect(item.log.rating, 4.2);
      expect(item.log.memo, 'よかった');
      expect(item.log.wantToBuy, isTrue);
      expect(item.perfume.nameJa, '柚子の朝');
      // brands は入れ子なので、平らにして PerfumeSummary へ渡している。
      expect(item.perfume.brandNameEn, 'Maison Hikari');
      expect(item.perfume.brandNameJa, 'メゾン・ヒカリ');
    });

    test('ブランドの日本語名が無くても落ちない', () {
      final item = TastingLogWithPerfume.fromJson({
        'id': 'l1',
        'perfume_id': 'p1',
        'rating': 3,
        'tested_at': '2026-08-30',
        'perfumes': {
          'id': 'p1',
          'name_en': 'Kohaku',
          'concentration': 'parfum',
          'is_verified': false,
          'brands': {'name_en': 'Atelier Nord'},
        },
      });

      expect(item.perfume.brandNameJa, isNull);
      expect(item.perfume.nameJa, isNull);
    });
  });

  group('LogSort', () {
    test('既定は新しい順で、選択肢に名前が付いている', () {
      expect(LogSort.values.first, LogSort.recent);
      for (final sort in LogSort.values) {
        expect(sort.label, isNotEmpty);
      }
    });
  });
}
