import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/collection_repository.dart';
import '../../models/collection.dart';

/// 所持品の絞り込み。null は「すべて」。
final collectionFilterProvider =
    NotifierProvider<CollectionFilterController, CollectionStatus?>(
      CollectionFilterController.new,
    );

class CollectionFilterController extends Notifier<CollectionStatus?> {
  @override
  CollectionStatus? build() => CollectionStatus.active;

  void set(CollectionStatus? status) => state = status;
}

/// 所持品の一覧。絞り込みが変わると読み直す。
final collectionItemsProvider = FutureProvider<List<CollectionItem>>((
  ref,
) async {
  final status = ref.watch(collectionFilterProvider);
  return ref.read(collectionRepositoryProvider).listItems(status: status);
});

/// 欲しいものの一覧。
final wishlistProvider = FutureProvider<List<WishlistItem>>((ref) async {
  return ref.read(collectionRepositoryProvider).listWishlist();
});
