import 'package:flutter_test/flutter_test.dart';
import 'package:perfume_app/src/data/perfume_repository.dart';

void main() {
  group('SearchFilters', () {
    test('既定では何も絞り込まない', () {
      const filters = SearchFilters();
      expect(filters.isEmpty, isTrue);
      expect(filters.activeCount, 0);
      expect(filters.includeUnverified, isTrue);
    });

    test('条件の数を数える', () {
      const filters = SearchFilters(noteIds: ['a', 'b'], accordIds: ['c']);
      expect(filters.isEmpty, isFalse);
      expect(filters.activeCount, 3);
    });

    test('copyWith は指定した項目だけ差し替える', () {
      const filters = SearchFilters(noteIds: ['a'], includeUnverified: false);
      final updated = filters.copyWith(accordIds: ['c']);
      expect(updated.noteIds, ['a']);
      expect(updated.accordIds, ['c']);
      expect(updated.includeUnverified, isFalse);
    });
  });
}
