import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_pro/data/models/quran_index.dart';

enum QuranTranslation { english, urdu, off }

/// The reader's own state, kept on this device: where they stopped, what they saved and how
/// they like the text. Shared by the Quran list ("continue") and the surah reader.
final class QuranService extends GetxService {
  QuranService(this._box);

  final GetStorage _box;
  static const _k = 'quranReader';

  static const minArabicSize = 22.0;
  static const maxArabicSize = 40.0;
  static const defaultArabicSize = 28.0;

  late final Map<String, dynamic> _saved = _box.read<Map<String, dynamic>>(_k) ?? const {};

  late final Rxn<AyahRef> _lastRead = Rxn<AyahRef>(switch (_saved['lastRead']) {
    [final int s, final int a] => (surah: s, ayah: a),
    _ => null,
  });
  late final RxSet<String> _bookmarks = <String>{
    for (final b in _saved['bookmarks'] as List<dynamic>? ?? const []) '$b',
  }.obs;
  late final RxDouble _arabicSize = (switch (_saved['arabicSize']) {
    final num n => n.toDouble().clamp(minArabicSize, maxArabicSize),
    _ => defaultArabicSize,
  }).obs;
  late final Rxn<QuranTranslation> _translation = Rxn<QuranTranslation>(
    QuranTranslation.values.asNameMap()[_saved['translation']],
  );

  AyahRef? get lastRead => _lastRead.value;
  double get arabicSize => _arabicSize.value;

  /// Null until the reader picks one; the reader then follows the app language.
  QuranTranslation? get translation => _translation.value;

  bool isBookmarked(AyahRef r) => _bookmarks.contains(_key(r));
  int get bookmarkCount => _bookmarks.length;

  set lastRead(AyahRef? r) {
    if (r == _lastRead.value) return;
    _lastRead.value = r;
    _save();
  }

  set arabicSize(double v) {
    _arabicSize.value = v.clamp(minArabicSize, maxArabicSize);
    _save();
  }

  set translation(QuranTranslation? t) {
    _translation.value = t;
    _save();
  }

  /// Returns whether [r] is bookmarked afterwards.
  bool toggleBookmark(AyahRef r) {
    final k = _key(r);
    final added = !_bookmarks.remove(k);
    if (added) _bookmarks.add(k);
    _save();
    return added;
  }

  static String _key(AyahRef r) => '${r.surah}:${r.ayah}';

  void _save() => unawaited(
    _box.write(_k, {
      if (_lastRead.value case final r?) 'lastRead': [r.surah, r.ayah],
      'bookmarks': _bookmarks.toList(),
      'arabicSize': _arabicSize.value,
      if (_translation.value case final t?) 'translation': t.name,
    }),
  );
}
