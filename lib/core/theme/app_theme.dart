import 'package:flutter/material.dart';
import 'package:quran_pro/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final light = brightness == Brightness.light;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.seed,
        brightness: brightness,
        surface: light ? AppColors.surface : null,
      ),
      scaffoldBackgroundColor: light ? AppColors.surface : null,
      fontFamily: 'Manrope',
      fontFamilyFallback: const ['NotoNastaliqUrdu', 'Amiri'],
    );
  }
}
