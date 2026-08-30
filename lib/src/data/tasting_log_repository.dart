import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase.dart';
import '../models/tasting_log.dart';

class TastingLogRepository {
  const TastingLogRepository();

  /// ログを保存する。user_id は RLS の既定値で埋まるため送らない。
  Future<TastingLog> create({
    required String perfumeId,
    required double rating,
    String? memo,
    String? method,
    DateTime? testedAt,
    bool wantToBuy = false,
  }) async {
    // RLS が user_id = auth.uid() を要求する。
    // ゲストはログのタブに入れない作りだが、ここでも防いでおく。
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('ログインしていないため保存できません');
    }

    final row = await supabase
        .from('tasting_logs')
        .insert({
          'user_id': userId,
          'perfume_id': perfumeId,
          'rating': rating,
          if (memo != null && memo.trim().isNotEmpty) 'memo': memo.trim(),
          if (method != null) 'method': method,
          if (testedAt != null) 'tested_at': _dateOnly(testedAt),
          'want_to_buy': wantToBuy,
        })
        .select()
        .single();

    return TastingLog.fromJson(row);
  }

  /// tested_at は date 型なので、時刻を落として渡す。
  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

final tastingLogRepositoryProvider = Provider<TastingLogRepository>(
  (ref) => const TastingLogRepository(),
);
