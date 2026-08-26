import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/theme/accord_colors.dart';

void main() {
  group('AccordColors', () {
    test('未知の slug でも落ちずにフォールバック色を返す', () {
      expect(AccordColors.of('does-not-exist'), AccordColors.fallback);
    });

    test('既知の slug にはフォールバック以外の色が割り当てられている', () {
      for (final slug in AccordColors.slugs) {
        expect(
          AccordColors.of(slug),
          isNot(AccordColors.fallback),
          reason: '$slug に色が割り当てられていない',
        );
      }
    });

    test('色は香調ごとに一意（色でカテゴリを覚えられるようにするため）', () {
      final seen = <Color, String>{};
      for (final slug in AccordColors.slugs) {
        final color = AccordColors.of(slug);
        expect(
          seen.containsKey(color),
          isFalse,
          reason: '$slug と ${seen[color]} の色が重複している',
        );
        seen[color] = slug;
      }
    });

    test('ダークテーマ版はライト版より明るい', () {
      for (final slug in AccordColors.slugs) {
        expect(
          AccordColors.onDark(slug).computeLuminance(),
          greaterThanOrEqualTo(AccordColors.of(slug).computeLuminance()),
          reason: '$slug のダーク版が明るくなっていない',
        );
      }
    });
  });
}
