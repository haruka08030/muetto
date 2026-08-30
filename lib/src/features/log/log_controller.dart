import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tasting_log_repository.dart';
import 'log_list_controller.dart';

/// ログ保存の進行状態。画面はこれを見てボタンを止める。
final logControllerProvider =
    NotifierProvider<LogController, AsyncValue<void>>(LogController.new);

class LogController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// 保存できたら true。呼び出し側はこれを見て画面を閉じる。
  Future<bool> save({
    required String perfumeId,
    required double rating,
    String? memo,
    String? method,
    bool wantToBuy = false,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(tastingLogRepositoryProvider).create(
        perfumeId: perfumeId,
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
      // 保存したものが一覧にすぐ出るようにする。
      ref.invalidate(logListProvider);
      ref.invalidate(logsForPerfumeProvider(perfumeId));
    }
    return !result.hasError;
  }
}
