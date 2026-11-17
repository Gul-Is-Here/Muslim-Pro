import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:quran_pro/data/models/learn.dart';

/// Bundled curriculum (assets/data/learn_curriculum.json): works offline, no account needed.
final class LearnLocalDataSource {
  const LearnLocalDataSource();

  static const asset = 'assets/data/learn_curriculum.json';

  Future<Curriculum> curriculum() async =>
      Curriculum.fromJson(jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>);
}
