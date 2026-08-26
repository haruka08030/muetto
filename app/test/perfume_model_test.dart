import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/models/perfume.dart';

void main() {
  group('PerfumeSummary.fromJson', () {
    test('search_perfumes の行を読める', () {
      final summary = PerfumeSummary.fromJson({
        'id': 'abc',
        'name_en': 'Rose Nocturne',
        'name_ja': 'ローズ ノクターン',
        'brand_name_en': 'Fixture Maison',
        'brand_name_ja': null,
        'concentration': 'edp',
        'release_year': 2019,
        'image_url': null,
        'is_verified': true,
      });
      expect(summary.nameJa, 'ローズ ノクターン');
      expect(summary.releaseYear, 2019);
      expect(summary.isVerified, isTrue);
    });

    test('欠けている項目があっても落ちない', () {
      final summary = PerfumeSummary.fromJson({
        'id': 'abc',
        'name_en': 'Vetiver Brut',
        'brand_name_en': 'Fixture Maison',
      });
      expect(summary.nameJa, isNull);
      expect(summary.concentration, 'other');
      expect(summary.isVerified, isFalse);
    });
  });

  group('PerfumeDetail', () {
    PerfumeNote note(String position, String name) =>
        PerfumeNote(position: position, nameEn: name, family: 'floral');

    final detail = PerfumeDetail(
      summary: PerfumeSummary.fromJson({
        'id': 'abc',
        'name_en': 'Rose Nocturne',
        'brand_name_en': 'Fixture Maison',
      }),
      notes: [
        note('top', 'rose'),
        note('top', 'bergamot'),
        note('base', 'oud'),
      ],
      accords: const [],
    );

    test('段ごとに絞り込める', () {
      expect(detail.notesAt('top').length, 2);
      expect(detail.notesAt('base').single.nameEn, 'oud');
    });

    test('存在しない段は空を返す', () {
      expect(detail.notesAt('middle'), isEmpty);
    });
  });

  group('PerfumeNote.fromJson', () {
    test('perfume_note_pyramid の列名に合わせている', () {
      // position は SQL の予約語のため、DB 側は pyramid_position で返す
      final parsed = PerfumeNote.fromJson({
        'pyramid_position': 'middle',
        'name_en': 'jasmine',
        'name_ja': 'ジャスミン',
        'family': 'white_floral',
      });
      expect(parsed.position, 'middle');
      expect(parsed.nameJa, 'ジャスミン');
    });
  });
}
