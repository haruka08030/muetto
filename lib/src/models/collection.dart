import 'perfume.dart';

/// 手に入れ方。DB の acquisition_type enum と一対一。
enum AcquisitionType {
  fullBottle('full_bottle', '現品'),
  decant('decant', '小分け'),
  sample('sample', 'サンプル'),
  subscription('subscription', 'サブスク'),
  gift('gift', 'もらいもの');

  const AcquisitionType(this.value, this.label);

  final String value;
  final String label;

  static AcquisitionType fromValue(String? value) =>
      AcquisitionType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => AcquisitionType.fullBottle,
      );
}

/// 所持品の状態。DB の collection_status enum と一対一。
enum CollectionStatus {
  active('active', '使用中'),
  finished('finished', '使い切った'),
  disposed('disposed', '手放した');

  const CollectionStatus(this.value, this.label);

  final String value;
  final String label;

  static CollectionStatus fromValue(String? value) =>
      CollectionStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => CollectionStatus.active,
      );
}

/// 持っている香水 1 本。
class CollectionItem {
  const CollectionItem({
    required this.id,
    required this.perfume,
    required this.acquisitionType,
    required this.remainingPct,
    required this.status,
    this.volumeMl,
    this.price,
    this.purchasedAt,
  });

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    final perfume = json['perfumes'] as Map<String, dynamic>;
    final brand = perfume['brands'] as Map<String, dynamic>;

    return CollectionItem(
      id: json['id'] as String,
      perfume: PerfumeSummary.fromJson({
        ...perfume,
        'brand_name_en': brand['name_en'],
        'brand_name_ja': brand['name_ja'],
      }),
      acquisitionType: AcquisitionType.fromValue(
        json['acquisition_type'] as String?,
      ),
      remainingPct: (json['remaining_pct'] as num?)?.toInt() ?? 100,
      status: CollectionStatus.fromValue(json['status'] as String?),
      volumeMl: _toDouble(json['volume_ml']),
      price: _toDouble(json['price']),
      purchasedAt: json['purchased_at'] == null
          ? null
          : DateTime.parse(json['purchased_at'] as String),
    );
  }

  /// numeric は数値でも文字列でも返る。
  static double? _toDouble(Object? value) => switch (value) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s),
    _ => null,
  };

  final String id;
  final PerfumeSummary perfume;
  final AcquisitionType acquisitionType;

  /// 残量のパーセント。0〜100。
  final int remainingPct;

  final CollectionStatus status;
  final double? volumeMl;
  final double? price;
  final DateTime? purchasedAt;

  /// 残っている量（ml）。容量が分からなければ null。
  double? get remainingMl =>
      volumeMl == null ? null : volumeMl! * remainingPct / 100;
}

/// 気になっている香水。
class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.perfume,
    required this.priority,
    this.memo,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final perfume = json['perfumes'] as Map<String, dynamic>;
    final brand = perfume['brands'] as Map<String, dynamic>;

    return WishlistItem(
      id: json['id'] as String,
      perfume: PerfumeSummary.fromJson({
        ...perfume,
        'brand_name_en': brand['name_en'],
        'brand_name_ja': brand['name_ja'],
      }),
      priority: (json['priority'] as num?)?.toInt() ?? 3,
      memo: json['memo'] as String?,
    );
  }

  final String id;
  final PerfumeSummary perfume;

  /// 1〜5。大きいほど欲しい。
  final int priority;

  final String? memo;
}
