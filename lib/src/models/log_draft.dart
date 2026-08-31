import 'dart:convert';

/// 保存しきれなかった試香ログ。端末に置いて、後でまとめて送る。
///
/// 店頭は電波が悪いことがある。そこで書けなくなるのが一番困るので、
/// 送信に失敗しても入力は失わせない（docs/screens.md 3）。
class LogDraft {
  const LogDraft({
    required this.id,
    required this.perfumeId,
    required this.perfumeNameEn,
    required this.rating,
    required this.createdAt,
    this.perfumeNameJa,
    this.brandNameEn,
    this.brandNameJa,
    this.memo,
  });

  factory LogDraft.fromJson(Map<String, dynamic> json) => LogDraft(
    id: json['id'] as String,
    perfumeId: json['perfume_id'] as String,
    perfumeNameEn: json['perfume_name_en'] as String,
    perfumeNameJa: json['perfume_name_ja'] as String?,
    brandNameEn: json['brand_name_en'] as String?,
    brandNameJa: json['brand_name_ja'] as String?,
    rating: (json['rating'] as num).toDouble(),
    memo: json['memo'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  static List<LogDraft> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    // 保存形式が壊れていても起動を止めない。下書きは失うが、
    // ここで例外を投げるとアプリ全体が使えなくなる。
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>().map(LogDraft.fromJson).toList();
    } on Object {
      return const [];
    }
  }

  static String encodeList(List<LogDraft> drafts) =>
      jsonEncode(drafts.map((draft) => draft.toJson()).toList());

  Map<String, dynamic> toJson() => {
    'id': id,
    'perfume_id': perfumeId,
    'perfume_name_en': perfumeNameEn,
    if (perfumeNameJa != null) 'perfume_name_ja': perfumeNameJa,
    if (brandNameEn != null) 'brand_name_en': brandNameEn,
    if (brandNameJa != null) 'brand_name_ja': brandNameJa,
    'rating': rating,
    if (memo != null) 'memo': memo,
    'created_at': createdAt.toIso8601String(),
  };

  /// 端末の中だけで使う ID。送信できたら消える。
  final String id;

  final String perfumeId;

  /// 香水名は下書きにも持つ。未送信の一覧を出すのに、
  /// 電波が無い状態で香水を引き直せないため。
  final String perfumeNameEn;
  final String? perfumeNameJa;
  final String? brandNameEn;
  final String? brandNameJa;

  final double rating;
  final String? memo;
  final DateTime createdAt;
}
