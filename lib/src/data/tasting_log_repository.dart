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

  /// 自分のログを一覧で取る。
  ///
  /// 香水名を出すために perfumes と brands を結合する。件数ぶん往復すると
  /// 遅いので、DB 側で 1 回にまとめる。RLS が user_id = auth.uid() で
  /// 絞るため、ここで user_id を条件に足す必要はない。
  Future<List<TastingLogWithPerfume>> list({
    LogSort sort = LogSort.recent,
    String? perfumeId,
    int limit = 30,
    int offset = 0,
  }) async {
    var query = supabase
        .from('tasting_logs')
        .select(
          'id, perfume_id, rating, memo, tested_at, method, want_to_buy, '
          'perfumes!inner(id, name_en, name_ja, concentration, release_year, '
          'image_url, is_verified, brands!inner(name_en, name_ja))',
        );

    // 香水別に見るとき（S-09 の「香水別」）。
    if (perfumeId != null) {
      query = query.eq('perfume_id', perfumeId);
    }

    final rows = await switch (sort) {
      // 同じ日に複数付けたときのために created_at を第二キーにする。
      LogSort.recent =>
        query
            .order('tested_at', ascending: false)
            .order('created_at', ascending: false),
      LogSort.rating =>
        query
            .order('rating', ascending: false)
            .order('tested_at', ascending: false),
    }.range(offset, offset + limit - 1);

    return rows
        .cast<Map<String, dynamic>>()
        .map(TastingLogWithPerfume.fromJson)
        .toList();
  }

  /// ログを書き換える。RLS が自分のものだけに絞る。
  ///
  /// memo と method は空にできる必要がある。省略と「消した」を
  /// 区別するため、呼び出し側は必ず両方を渡す。
  Future<void> update({
    required String logId,
    required double rating,
    required String? memo,
    required String? method,
    required bool wantToBuy,
  }) async {
    final trimmedMemo = memo?.trim();

    await supabase
        .from('tasting_logs')
        .update({
          'rating': rating,
          'memo': (trimmedMemo == null || trimmedMemo.isEmpty)
              ? null
              : trimmedMemo,
          'method': method,
          'want_to_buy': wantToBuy,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', logId);
  }

  /// ログを消す。RLS が自分のものだけに絞る。
  Future<void> delete(String logId) async {
    await supabase.from('tasting_logs').delete().eq('id', logId);
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
