import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/models/collection.dart';

void main() {
  group('AcquisitionType / CollectionStatus', () {
    test('DB の enum と値が一致している', () {
      // ずれると保存時に 22P02 で落ちる。
      expect(AcquisitionType.values.map((t) => t.value), [
        'full_bottle',
        'decant',
        'sample',
        'subscription',
        'gift',
      ]);
      expect(CollectionStatus.values.map((s) => s.value), [
        'active',
        'finished',
        'disposed',
      ]);
    });

    test('知らない値が来ても既定に落ちる', () {
      // DB に enum が増えてもアプリが落ちないようにする。
      expect(AcquisitionType.fromValue('unknown'), AcquisitionType.fullBottle);
      expect(CollectionStatus.fromValue(null), CollectionStatus.active);
    });
  });

  group('CollectionItem', () {
    test('結合した香水を読み、残量 ml を計算する', () {
      final item = CollectionItem.fromJson(_row(volumeMl: 50, remaining: 40));

      expect(item.perfume.nameJa, '柚子の朝');
      expect(item.perfume.brandNameEn, 'Maison Hikari');
      expect(item.remainingPct, 40);
      expect(item.remainingMl, 20);
    });

    test('容量が分からなければ残量 ml は出さない', () {
      final item = CollectionItem.fromJson(_row(volumeMl: null, remaining: 40));

      expect(item.remainingMl, isNull);
    });

    test('numeric が文字列で返っても読める', () {
      final row = _row(volumeMl: null, remaining: 50)
        ..['volume_ml'] = '30.5'
        ..['price'] = '12000';
      final item = CollectionItem.fromJson(row);

      expect(item.volumeMl, 30.5);
      expect(item.price, 12000);
    });
  });

  group('WishlistItem', () {
    test('優先度とメモを読む', () {
      final item = WishlistItem.fromJson({
        'id': 'w1',
        'priority': 5,
        'memo': '来月試す',
        'perfumes': _perfume(),
      });

      expect(item.priority, 5);
      expect(item.memo, '来月試す');
      expect(item.perfume.nameJa, '柚子の朝');
    });

    test('優先度が無ければ真ん中の 3', () {
      final item = WishlistItem.fromJson({'id': 'w1', 'perfumes': _perfume()});

      expect(item.priority, 3);
    });
  });
}

Map<String, dynamic> _row({
  required double? volumeMl,
  required int remaining,
}) => {
  'id': 'c1',
  'acquisition_type': 'full_bottle',
  'volume_ml': volumeMl,
  'remaining_pct': remaining,
  'status': 'active',
  'perfumes': _perfume(),
};

Map<String, dynamic> _perfume() => {
  'id': 'p1',
  'name_en': 'Yuzu no Asa',
  'name_ja': '柚子の朝',
  'concentration': 'edt',
  'is_verified': true,
  'brands': {'name_en': 'Maison Hikari', 'name_ja': 'メゾン・ヒカリ'},
};
