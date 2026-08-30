import 'package:flutter/material.dart';

/// アプリ全体のデザイントークン。
///
/// 香水という題材に合わせ、彩度を抑えたニュートラルなベースに、
/// 香調カテゴリの色（AccordColors）をアクセントとして載せる。
abstract final class AppColors {
  static const seed = Color(0xFF8B6B4A); // ウッディ寄りの落ち着いた褐色
  static const lightSurface = Color(0xFFFBF8F5);
  static const darkSurface = Color(0xFF1A1715);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class AppRadius {
  static const double card = 16;
  static const double chip = 24;
}

/// カードの見た目。
///
/// ThemeData.cardTheme の型名は Flutter のバージョンによって変わるため、
/// テーマでは上書きせず、使う側でこの shape を渡す。
abstract final class AppShapes {
  static RoundedRectangleBorder get card => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.card),
  );
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppColors.lightSurface);
  static ThemeData dark() => _build(Brightness.dark, AppColors.darkSurface);

  static ThemeData _build(Brightness brightness, Color surface) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
