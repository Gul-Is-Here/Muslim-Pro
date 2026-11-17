import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/models/adhkar.dart';
import 'package:quran_pro/domain/repositories/adhkar_repository.dart';

/// The adhkar and how many times each was said today. Counts start fresh every day.
/// Shared by the Adhkar screen and the Home tile.
final class AdhkarService extends GetxService {
  AdhkarService(this._repo, this._box);

  final AdhkarRepository _repo;
  final GetStorage _box;
  static const _k = 'adhkarToday';

  final Rxn<AdhkarBook> _book = Rxn<AdhkarBook>();
  late final RxMap<int, int> _counts = _restore().obs;
  late String _day = _today();

  AdhkarBook? get book => _book.value;

  static String _today() {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  Map<int, int> _restore() {
    final saved = _box.read<Map<String, dynamic>>(_k);
    if (saved == null || saved['day'] != _today()) return {};
    return {
      for (final MapEntry(:key, :value) in (saved['counts'] as Map<String, dynamic>? ?? {}).entries)
        if (int.tryParse(key) case final n? when value is int) n: value,
    };
  }

  /// A new day since the counts were taken: start over.
  void _rollOver() {
    if (_day == _today()) return;
    _day = _today();
    _counts.clear();
  }

  int countOf(Dhikr d) {
    _rollOver();
    return (_counts[d.number] ?? 0).clamp(0, d.repeat);
  }

  bool isDone(Dhikr d) => countOf(d) >= d.repeat;

  /// One more repetition; returns true when this tap completed the dhikr.
  bool count(Dhikr d) {
    if (isDone(d)) return false;
    _counts[d.number] = countOf(d) + 1;
    _save();
    return isDone(d);
  }

  void reset(Iterable<Dhikr> items) {
    for (final d in items) {
      _counts.remove(d.number);
    }
    _save();
  }

  int doneIn(AdhkarCategory c) => book?.of(c).where(isDone).length ?? 0;
  int totalIn(AdhkarCategory c) => book?.of(c).length ?? 0;

  void _save() => unawaited(
    _box.write(_k, {
      'day': _day,
      'counts': {for (final e in _counts.entries) '${e.key}': e.value},
    }),
  );

  Future<void> load() async {
    if (_book.value != null) return;
    if (await _repo.book() case Ok(:final value)) _book.value = value;
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }
}
