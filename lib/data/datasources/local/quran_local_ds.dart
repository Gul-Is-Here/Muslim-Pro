import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:quran_pro/data/models/quran_index.dart';

/// Bundled Quran: surah/juz index (assets/data/quran_index.json) and one text file per surah
/// (assets/quran/NNN.json, Tanzil Uthmani + Saheeh International + Jalandhry), all offline.
final class QuranLocalDataSource {
  const QuranLocalDataSource();

  static const asset = 'assets/data/quran_index.json';

  Future<QuranIndex> index() async =>
      QuranIndex.fromJson(jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>);

  Future<SurahText> surah(int number) async {
    final path = 'assets/quran/${number.toString().padLeft(3, '0')}.json';
    return SurahText.fromJson(
      jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>,
    );
  }
}
