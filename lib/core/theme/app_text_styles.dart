import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const quranArabic = TextStyle(fontFamily: 'Amiri', fontSize: 26, height: 2);
  static const urdu = TextStyle(fontFamily: 'NotoNastaliqUrdu', height: 2.2);

  /// Countdown digits: fixed-width so the timer does not jitter every second.
  static const timer = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
