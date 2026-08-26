/// 検索結果の 1 件。DB の search_perfumes が返す行に対応する。
class PerfumeSummary {
  const PerfumeSummary({
    required this.id,
    required this.nameEn,
    required this.brandNameEn,
    required this.concentration,
    required this.isVerified,
    this.nameJa,
    this.brandNameJa,
    this.releaseYear,
    this.imageUrl,
  });

  factory PerfumeSummary.fromJson(Map<String, dynamic> json) => PerfumeSummary(
    id: json['id'] as String,
    nameEn: json['name_en'] as String,
    nameJa: json['name_ja'] as String?,
    brandNameEn: json['brand_name_en'] as String,
    brandNameJa: json['brand_name_ja'] as String?,
    concentration: json['concentration'] as String? ?? 'other',
    releaseYear: json['release_year'] as int?,
    imageUrl: json['image_url'] as String?,
    isVerified: json['is_verified'] as bool? ?? false,
  );

  final String id;
  final String nameEn;
  final String? nameJa;
  final String brandNameEn;
  final String? brandNameJa;
  final String concentration;
  final int? releaseYear;
  final String? imageUrl;
  final bool isVerified;
}

/// ノートピラミッドの 1 要素。
class PerfumeNote {
  const PerfumeNote({
    required this.position,
    required this.nameEn,
    required this.family,
    this.nameJa,
  });

  factory PerfumeNote.fromJson(Map<String, dynamic> json) => PerfumeNote(
    position: json['pyramid_position'] as String? ?? 'unspecified',
    nameEn: json['name_en'] as String,
    nameJa: json['name_ja'] as String?,
    family: json['family'] as String? ?? 'other',
  );

  /// 'top' / 'middle' / 'base' / 'unspecified'
  final String position;
  final String nameEn;
  final String? nameJa;
  final String family;
}

/// 香調バーの 1 要素。
class PerfumeAccord {
  const PerfumeAccord({
    required this.slug,
    required this.nameEn,
    required this.strength,
    this.nameJa,
  });

  factory PerfumeAccord.fromJson(Map<String, dynamic> json) => PerfumeAccord(
    slug: json['slug'] as String,
    nameEn: json['name_en'] as String,
    nameJa: json['name_ja'] as String?,
    strength: (json['strength'] as num?)?.toDouble() ?? 1.0,
  );

  final String slug;
  final String nameEn;
  final String? nameJa;
  final double strength;
}

/// 香水詳細。
class PerfumeDetail {
  const PerfumeDetail({
    required this.summary,
    required this.notes,
    required this.accords,
    this.perfumer,
  });

  final PerfumeSummary summary;
  final List<PerfumeNote> notes;
  final List<PerfumeAccord> accords;
  final String? perfumer;

  List<PerfumeNote> notesAt(String position) =>
      notes.where((n) => n.position == position).toList();
}
