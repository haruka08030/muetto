import 'package:flutter/material.dart';

/// 香調カテゴリの色。
///
/// この色は検索フィルタ・香水詳細・分析グラフで共通に使う（docs/screens.md 6）。
/// ユーザーが「色でカテゴリを覚えられる」ことを狙っているため、
/// 画面ごとに別の色を割り当ててはならない。
///
/// slug は supabase/seed/0001_notes_accords.sql の accords.slug と対応する。
abstract final class AccordColors {
  static const Map<String, Color> _light = {
    'floral': Color(0xFFD98BA8),
    'citrus': Color(0xFFD9B441),
    'fresh': Color(0xFF7FBFAE),
    'green': Color(0xFF7BA05B),
    'fruity': Color(0xFFD97D6B),
    'sweet': Color(0xFFDDA15E),
    'gourmand': Color(0xFFB07B4F),
    'creamy': Color(0xFFD9C3A5),
    'spicy': Color(0xFFC1553B),
    'woody': Color(0xFF8B6B4A),
    'resinous': Color(0xFFA8763E),
    'oriental': Color(0xFF9C6B8E),
    'smoky': Color(0xFF6E6A66),
    'leathery': Color(0xFF7A5240),
    'earthy': Color(0xFF7D7259),
    'animal': Color(0xFF8C6E63),
    'powdery': Color(0xFFC9BBC8),
    'aquatic': Color(0xFF6A9BC3),
    'chypre': Color(0xFF6F8A6A),
    'fougere': Color(0xFF8AA07E),
    'synthetic': Color(0xFF9AA4AE),
  };

  /// 未知の slug に対して使う色。マスタに無い香調が来ても落とさない。
  static const Color fallback = Color(0xFF9E9E9E);

  static Color of(String accordSlug) => _light[accordSlug] ?? fallback;

  /// ダークテーマでは彩度を保ったまま明度を上げる。
  static Color onDark(String accordSlug) {
    final base = HSLColor.fromColor(of(accordSlug));
    return base.withLightness((base.lightness + 0.15).clamp(0.0, 1.0)).toColor();
  }

  static Iterable<String> get slugs => _light.keys;
}
