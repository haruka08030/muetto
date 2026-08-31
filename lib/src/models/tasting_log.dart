import 'perfume.dart';

/// 試香の記録。DB の tasting_logs 1 行に対応する。
class TastingLog {
  const TastingLog({
    required this.id,
    required this.perfumeId,
    required this.rating,
    required this.testedAt,
    this.memo,
  });

  factory TastingLog.fromJson(Map<String, dynamic> json) => TastingLog(
    id: json['id'] as String,
    perfumeId: json['perfume_id'] as String,
    // numeric は数値でも文字列でも返りうる。
    rating: _toDouble(json['rating']),
    memo: json['memo'] as String?,
    testedAt: DateTime.parse(json['tested_at'] as String),
  );

  static double _toDouble(Object? value) => switch (value) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s) ?? 0,
    _ => 0,
  };

  final String id;
  final String perfumeId;

  /// 総合評価。1.0〜5.0 の 0.1 刻み（ADR-004）。
  final double rating;

  final String? memo;
  final DateTime testedAt;
}

/// 一覧に出すための、ログと香水を組にしたもの。
///
/// 一覧では香水名を必ず出すので、ログ単体では足りない。
/// 別々に取ると件数ぶんの往復が要るため、DB 側で結合して 1 回で取る。
class TastingLogWithPerfume {
  const TastingLogWithPerfume({required this.log, required this.perfume});

  factory TastingLogWithPerfume.fromJson(Map<String, dynamic> json) {
    final perfume = json['perfumes'] as Map<String, dynamic>;
    final brand = perfume['brands'] as Map<String, dynamic>;

    return TastingLogWithPerfume(
      log: TastingLog.fromJson(json),
      perfume: PerfumeSummary.fromJson({
        ...perfume,
        'brand_name_en': brand['name_en'],
        'brand_name_ja': brand['name_ja'],
      }),
    );
  }

  final TastingLog log;
  final PerfumeSummary perfume;
}

/// 一覧の並び順（docs/screens.md 1、S-09）。
enum LogSort {
  /// 試した日の新しい順。既定。
  recent('新しい順'),

  /// 評価の高い順。
  rating('評価の高い順');

  const LogSort(this.label);

  final String label;
}
