import 'package:flutter/painting.dart';

/// Learn tab palette: the app's emerald with a warm gold accent and parchment surfaces.
abstract final class LearnColors {
  static const primary = Color(0xFF004334);
  static const primaryContainer = Color(0xFF0F5C4A);
  static const primaryFixed = Color(0xFFABF1D9);
  static const primaryFixedDim = Color(0xFF8FD4BD);
  static const gold = Color(0xFF795902);
  static const goldContainer = Color(0xFFFDD275);
  static const goldFixed = Color(0xFFFFDF9E);
  static const goldFixedDim = Color(0xFFEBC166);
  static const onGoldFixed = Color(0xFF261A00);
  static const onGoldContainer = Color(0xFF775800);
  static const trail = Color(0xFFEBDFD2);
  static const trailDone = Color(0xFFC9A24B);
  static const surface = Color(0xFFFCF9F8);
  static const low = Color(0xFFF6F3F2);
  static const container = Color(0xFFF0EDED);
  static const high = Color(0xFFEAE7E7);
  static const highest = Color(0xFFE5E2E1);
  static const onSurface = Color(0xFF1B1B1C);
  static const onVariant = Color(0xFF3F4945);
  static const outline = Color(0xFF6F7975);
  static const error = Color(0xFFBA1A1A);

  static const shadow = [BoxShadow(color: Color(0x0F0F5C4A), blurRadius: 8, offset: Offset(0, 2))];
}
