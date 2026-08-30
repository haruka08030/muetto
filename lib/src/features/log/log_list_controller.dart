import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tasting_log_repository.dart';
import '../../models/tasting_log.dart';

/// 一覧の並び順。切り替えると [logListProvider] が読み直す。
final logSortProvider = NotifierProvider<LogSortController, LogSort>(
  LogSortController.new,
);

class LogSortController extends Notifier<LogSort> {
  @override
  LogSort build() => LogSort.recent;

  void set(LogSort sort) => state = sort;
}

/// 自分のログ一覧。
///
/// 並び順が変わると自動で読み直す。保存や削除のあとは
/// ref.invalidate(logListProvider) で明示的に読み直す。
final logListProvider = FutureProvider<List<TastingLogWithPerfume>>((
  ref,
) async {
  final sort = ref.watch(logSortProvider);
  return ref.read(tastingLogRepositoryProvider).list(sort: sort);
});

/// 特定の香水に絞ったログ。香水詳細から使う。
final logsForPerfumeProvider =
    FutureProvider.family<List<TastingLogWithPerfume>, String>((
      ref,
      perfumeId,
    ) async {
      return ref.read(tastingLogRepositoryProvider).list(perfumeId: perfumeId);
    });
