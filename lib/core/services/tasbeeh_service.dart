import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_pro/data/models/tasbeeh.dart';

/// The tasbeeh counter, shared by Home and the Tasbeeh screen and saved on every change.
final class TasbeehService extends GetxService {
  TasbeehService(this._box);

  final GetStorage _box;
  static const _k = 'tasbeeh';

  late final Rx<TasbeehState> _state = _load().obs;

  TasbeehState get state => _state.value;
  set state(TasbeehState s) {
    _state.value = s;
    unawaited(_box.write(_k, s.toJson()));
  }

  TasbeehState _load() {
    try {
      final json = _box.read<Map<String, dynamic>>(_k);
      return json == null ? const TasbeehState() : TasbeehState.fromJson(json);
    } on Object {
      return const TasbeehState(); // corrupt or old-format data: start fresh rather than crash
    }
  }
}
