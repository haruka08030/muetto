import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/collection_repository.dart';
import '../../data/draft_store.dart';
import '../../data/tasting_log_repository.dart';
import '../../models/log_draft.dart';
import '../../models/perfume.dart';
import '../collection/collection_controller.dart';
import 'draft_sync.dart';
import 'log_list_controller.dart';

/// 保存の結果。オフラインでも入力は失わないので、成否の二択にしない。
enum LogSaveResult {
  /// サーバに届いた。
  saved,

  /// 端末に下書きとして残した。後で自動的に送る。
  draft,

  /// 保存できなかった。ログインしていないなど、待っても解決しない場合。
  failed,
}

/// ログ保存の進行状態。画面はこれを見てボタンを止める。
final logControllerProvider = NotifierProvider<LogController, AsyncValue<void>>(
  LogController.new,
);

class LogController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// ログを保存する。
  ///
  /// 送信に失敗しても false は返さない。端末に下書きとして残し、
  /// 次に送れるときにまとめて送る。店頭で電波が悪いのはよくあることで、
  /// そこで入力を失わせないのがこの画面のいちばんの役目
  /// （docs/screens.md 3）。
  ///
  /// [perfume] は下書きに香水名を持たせるために要る。未送信の一覧を
  /// 出すとき、電波が無い状態で香水を引き直せない。
  Future<LogSaveResult> save({
    required PerfumeSummary perfume,
    required double rating,
    String? memo,
    String? method,
    bool wantToBuy = false,
  }) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(tastingLogRepositoryProvider)
          .create(
            perfumeId: perfume.id,
            rating: rating,
            memo: memo,
            method: method,
            wantToBuy: wantToBuy,
          );

      if (wantToBuy) {
        await _addToWishlist(perfume.id);
      }

      state = const AsyncData(null);
      ref.invalidate(logListProvider);
      ref.invalidate(recentLogsProvider);
      ref.invalidate(logsForPerfumeProvider(perfume.id));

      // 溜まっていた下書きも、送れるうちに送ってしまう。
      unawaited(ref.read(draftSyncProvider.notifier).flush());

      return LogSaveResult.saved;
    } on Object {
      // ログインしていない場合はここに来ても意味がない。
      // 下書きは同じ端末の同じ利用者のものとして送るため。
      if (!ref.read(tastingLogRepositoryProvider).isSignedIn) {
        state = AsyncError(
          StateError('ログインしていないため保存できません'),
          StackTrace.current,
        );
        return LogSaveResult.failed;
      }

      await ref
          .read(draftStoreProvider)
          .add(
            LogDraft(
              id: _newDraftId(),
              perfumeId: perfume.id,
              perfumeNameEn: perfume.nameEn,
              perfumeNameJa: perfume.nameJa,
              brandNameEn: perfume.brandNameEn,
              brandNameJa: perfume.brandNameJa,
              rating: rating,
              memo: memo,
              method: method,
              wantToBuy: wantToBuy,
              createdAt: DateTime.now(),
            ),
          );

      state = const AsyncData(null);
      ref.invalidate(draftsProvider);
      return LogSaveResult.draft;
    }
  }

  /// 「買いたい」を立てたらウィッシュリストにも入れる
  /// （docs/requirements.md 5.5）。
  ///
  /// これが失敗してもログの保存は取り消さない。本体はログのほうで、
  /// 巻き戻すと入力そのものを失う。
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

  /// 端末の中だけで一意ならよい。時刻だけだと、続けて保存したときに
  /// 同じ値になりうるのでカウンタを足す。
  static var _draftCounter = 0;
  static String _newDraftId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_draftCounter++}';

  /// 既存のログを書き換える。保存できたら true。
  Future<bool> update({
    required String logId,
    required String perfumeId,
    required double rating,
    required String? memo,
    required String? method,
    required bool wantToBuy,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(tastingLogRepositoryProvider)
          .update(
            logId: logId,
            rating: rating,
            memo: memo,
            method: method,
            wantToBuy: wantToBuy,
          ),
    );
    state = result.hasError
        ? AsyncError(result.error!, StackTrace.current)
        : const AsyncData(null);

    if (!result.hasError) {
      ref.invalidate(logListProvider);
      ref.invalidate(recentLogsProvider);
      ref.invalidate(logsForPerfumeProvider(perfumeId));
    }
    return !result.hasError;
  }
}
