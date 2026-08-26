import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/models/localized.dart';

void main() {
  group('localizedName', () {
    test('日本語ロケールでは日本語名を返す', () {
      expect(localizedName(nameEn: 'Rose', nameJa: 'ローズ'), 'ローズ');
    });

    test('日本語名が無ければ英語名にフォールバックする', () {
      expect(localizedName(nameEn: 'Rose'), 'Rose');
    });

    test('日本語名が空白だけならフォールバックする', () {
      expect(localizedName(nameEn: 'Rose', nameJa: '   '), 'Rose');
    });

    test('日本語以外のロケールでは英語名を返す', () {
      expect(
        localizedName(nameEn: 'Rose', nameJa: 'ローズ', locale: 'en'),
        'Rose',
      );
    });
  });

  group('concentrationLabel', () {
    test('既知の賦香率に日本語名が付く', () {
      expect(concentrationLabel('edt'), 'オードトワレ');
      expect(concentrationLabel('edp'), 'オードパルファム');
      expect(concentrationLabel('extrait'), 'エクストレ');
    });

    test('other は表示しない（空文字を返す）', () {
      expect(concentrationLabel('other'), '');
      expect(concentrationLabel('未知の値'), '');
    });
  });
}
