import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/features/collection/collection_controller.dart';
import 'package:muetto/src/features/collection/collection_items_view.dart';
import 'package:muetto/src/features/collection/wishlist_view.dart';
import 'package:muetto/src/models/collection.dart';

void main() {
  testWidgets('所持品が空なら追加の仕方を案内する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionItemsProvider.overrideWith(
            (ref) async => const <CollectionItem>[],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CollectionItemsView())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('登録した香水がありません'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('所持品は残量と手に入れ方を出す', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionItemsProvider.overrideWith(
            (ref) async => [
              CollectionItem.fromJson({
                'id': 'c1',
                'acquisition_type': 'decant',
                'volume_ml': 10,
                'remaining_pct': 60,
                'status': 'active',
                'perfumes': _perfume(),
              }),
            ],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CollectionItemsView())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('柚子の朝'), findsOneWidget);
    expect(find.text('小分け'), findsOneWidget);
    expect(find.textContaining('残り 60%'), findsOneWidget);
    // 容量が分かるので ml も出る。
    expect(find.textContaining('6 ml'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('欲しいものは優先度の高い順に出す', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wishlistProvider.overrideWith(
            (ref) async => [
              WishlistItem.fromJson({
                'id': 'w1',
                'priority': 5,
                'memo': '来月試す',
                'perfumes': _perfume(),
              }),
            ],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: WishlistView())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('柚子の朝'), findsOneWidget);
    expect(find.text('来月試す'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _perfume() => {
  'id': 'p1',
  'name_en': 'Yuzu no Asa',
  'name_ja': '柚子の朝',
  'concentration': 'edt',
  'is_verified': true,
  'brands': {'name_en': 'Maison Hikari', 'name_ja': 'メゾン・ヒカリ'},
};
