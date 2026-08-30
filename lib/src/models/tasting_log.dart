/// 試香の記録。DB の tasting_logs 1 行に対応する。
class TastingLog {
  const TastingLog({
    required this.id,
    required this.perfumeId,
    required this.rating,
    required this.testedAt,
    this.memo,
    this.method,
    this.wantToBuy = false,
  });

  factory TastingLog.fromJson(Map<String, dynamic> json) => TastingLog(
    id: json['id'] as String,
    perfumeId: json['perfume_id'] as String,
    // numeric は数値でも文字列でも返りうる。
    rating: _toDouble(json['rating']),
    memo: json['memo'] as String?,
    testedAt: DateTime.parse(json['tested_at'] as String),
    method: json['method'] as String?,
    wantToBuy: json['want_to_buy'] as bool? ?? false,
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

  /// 試した方法。null は未選択。値は DB の tasting_method に合わせる。
  final String? method;

  final bool wantToBuy;
}

/// 試した方法の選択肢。DB の tasting_method enum と一対一で対応する。
enum TastingMethod {
  blotter('blotter', 'ムエット'),
  skin('skin', '肌につけた'),
  sample('sample', 'サンプル'),
  owned('owned', '手持ち');

  const TastingMethod(this.value, this.label);

  /// DB に保存する値。
  final String value;

  /// 画面に出す名前。
  final String label;
}
