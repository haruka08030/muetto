import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/collection_repository.dart';
import '../../data/draft_store.dart';
import '../../data/tasting_log_repository.dart';
import '../../models/log_draft.dart';
import '../collection/collection_controller.dart';
import 'log_list_controller.dart';

/// 端末に残っている未送信のログ。
final draftsProvider = FutureProvider<List<LogDraft>>((ref) async {
  return ref.read(draftStoreProvider).load();
});

/// 未送信の下書きをまとめて送る。
///
/// 起動時と保存の直後に呼ぶ。通信の可否は事前に調べない。
/// 電波が立っていてもサーバに届かないことがあり、実際に送ってみるのが
/// いちばん確かなため。
final draftSyncProvider = NotifierProvider<DraftSync, AsyncValue<int>>(
  DraftSync.new,
);

class DraftSync extends Notifier<AsyncValue<int>> {
  @override
  AsyncValue<int> build() => const AsyncData(0);

  /// 送れたぶんだけ消す。送れなかったものは端末に残す。
  ///
  /// 戻り値は送れた件数。1 件が失敗しても残りは試す。
  /// 特定の 1 件が壊れているせいで、他が永久に送れないのを避ける。
  Future<int> flush() async {
    final store = ref.read(draftStoreProvider);
    final drafts = await store.load();
    if (drafts.isEmpty) {
      return 0;
    }

    state = const AsyncLoading();
    var sent = 0;

    for (final draft in drafts) {
      try {
        await ref
            .read(tastingLogRepositoryProvider)
            .create(
              perfumeId: draft.perfumeId,
              rating: draft.rating,
              memo: draft.memo,
              method: draft.method,
              testedAt: draft.createdAt,
              wantToBuy: draft.wantToBuy,
            );
        await store.remove(draft.id);
        sent++;

        if (draft.wantToBuy) {
          await _addToWishlist(draft.perfumeId);
        }
      } on Object {
        // 送れなかったものは残す。次の機会に再び試す。
        continue;
      }
    }

    state = AsyncData(sent);

    if (sent > 0) {
      ref.invalidate(logListProvider);
      ref.invalidate(recentLogsProvider);
      ref.invalidate(draftsProvider);
    }
    return sent;
  }

  /// 「買いたい」を立てたらウィッシュリストにも入れる
  /// （docs/requirements.md 5.5）。
  ///
  /// ここが失敗してもログの保存は取り消さない。
  /// 本体はログで、こちらは付随なので、巻き戻すと損が大きい。
  Future<void> _addToWishlist(String perfumeId) async {
    try {
      await ref
          .read(collectionRepositoryProvider)
          .addToWishlist(perfumeId: perfumeId);
      ref.invalidate(wishlistProvider);
    } on Object {
      return;
    }
  }
}
