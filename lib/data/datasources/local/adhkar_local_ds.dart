import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:quran_pro/data/models/adhkar.dart';

/// Bundled Hisn al-Muslim adhkar (assets/data/adhkar.json): text works offline.
final class AdhkarLocalDataSource {
  const AdhkarLocalDataSource();

  static const asset = 'assets/data/adhkar.json';

  Future<AdhkarBook> book() async =>
      AdhkarBook.fromJson(jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>);
}
