import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_pro/data/models/ramadan_progress.dart';

/// The fasting log, kept on this device. Shared by the Ramadan tracker and the Home tile.
final class RamadanService extends GetxService {
  RamadanService(this._box);

  final GetStorage _box;
  static const _k = 'ramadan';

  late final Rx<RamadanProgress> _progress = (switch (_box.read<Map<String, dynamic>>(_k)) {
    final json? => RamadanProgress.fromJson(json),
    null => const RamadanProgress(),
  }).obs;

  RamadanProgress get progress => _progress.value;
  set progress(RamadanProgress p) {
    _progress.value = p;
    unawaited(_box.write(_k, p.toJson()));
  }
}
