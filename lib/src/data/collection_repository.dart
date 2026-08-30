import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase.dart';
import '../models/collection.dart';

/// 香水の情報を一緒に引くための select 句。
/// 一覧では必ず名前を出すので、件数ぶん往復しないよう DB 側で結合する。
const _perfumeJoin =
    'perfumes!inner(id, name_en, name_ja, concentration, release_year, '
    'image_url, is_verified, brands!inner(name_en, name_ja))';

class CollectionRepository {
  const CollectionRepository();

  /// 所持品を取る。RLS が user_id で絞るので条件に足さない。
  Future<List<CollectionItem>> listItems({CollectionStatus? status}) async {
    var query = supabase
        .from('collection_items')
        .select(
          'id, acquisition_type, volume_ml, remaining_pct, price, '
          'purchased_at, status, $_perfumeJoin',
        );

    if (status != null) {
      query = query.eq('status', status.value);
    }

    final rows = await query.order('created_at', ascending: false);
    return rows
        .cast<Map<String, dynamic>>()
        .map(CollectionItem.fromJson)
        .toList();
  }

  Future<void> addItem({
    required String perfumeId,
    required AcquisitionType acquisitionType,
    double? volumeMl,
    double? price,
  }) async {
    await supabase.from('collection_items').insert({
      'user_id': _requireUserId(),
      'perfume_id': perfumeId,
      'acquisition_type': acquisitionType.value,
      if (volumeMl != null) 'volume_ml': volumeMl,
      if (price != null) 'price': price,
    });
  }

  /// 残量を更新し、履歴にも残す。
  ///
  /// 履歴は使い切り時期の推定に使う（docs/data-model.md）。
  /// 現在値だけ持つと、いつどれだけ減ったかが分からなくなる。
  Future<void> updateRemaining({
    required String itemId,
    required int remainingPct,
  }) async {
    await supabase
        .from('collection_items')
        .update({
          'remaining_pct': remainingPct,
          'updated_at': DateTime.now().toIso8601String(),
          // 使い切ったら状態も進める。手で変える手間を省く。
          if (remainingPct == 0) 'status': CollectionStatus.finished.value,
        })
        .eq('id', itemId);

    await supabase.from('collection_usage_history').insert({
      'collection_item_id': itemId,
      'remaining_pct': remainingPct,
    });
  }

  Future<void> updateStatus({
    required String itemId,
    required CollectionStatus status,
  }) async {
    await supabase
        .from('collection_items')
        .update({'status': status.value})
        .eq('id', itemId);
  }

  Future<void> deleteItem(String itemId) async {
    await supabase.from('collection_items').delete().eq('id', itemId);
  }

  Future<List<WishlistItem>> listWishlist() async {
    final rows = await supabase
        .from('wishlist_items')
        .select('id, priority, memo, $_perfumeJoin')
        .order('priority', ascending: false)
        .order('created_at', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map(WishlistItem.fromJson)
        .toList();
  }

  /// 欲しいものに足す。同じ香水を二重に入れない（DB の unique 制約）。
  Future<void> addToWishlist({
    required String perfumeId,
    int priority = 3,
    String? memo,
  }) async {
    await supabase.from('wishlist_items').upsert({
      'user_id': _requireUserId(),
      'perfume_id': perfumeId,
      'priority': priority,
      if (memo != null && memo.trim().isNotEmpty) 'memo': memo.trim(),
    }, onConflict: 'user_id, perfume_id');
  }

  Future<void> deleteWishlistItem(String itemId) async {
    await supabase.from('wishlist_items').delete().eq('id', itemId);
  }

  /// RLS が user_id = auth.uid() を要求する。
  /// ゲストはこれらの画面に入れない作りだが、ここでも防いでおく。
  static String _requireUserId() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('ログインしていないため保存できません');
    }
    return userId;
  }
}

final collectionRepositoryProvider = Provider<CollectionRepository>(
  (ref) => const CollectionRepository(),
);
