import 'package:get/get.dart';
import 'package:quran_pro/core/utils/app_log.dart';
import 'package:quran_pro/data/datasources/local/quran_audio_files.dart';
import 'package:quran_pro/data/models/quran_index.dart';

/// Which surahs are saved for offline listening, and the ones downloading now. App-wide, so a
/// download keeps going when the reader is closed and every screen shows the same state.
final class SurahDownloadService extends GetxService {
  SurahDownloadService(this._files, this._remote);

  final QuranAudioFiles _files;
  final Uri Function(int surah, int ayah) _remote;

  late final RxSet<int> _done = _files.completeSurahs().obs;
  final RxMap<int, double> _progress = <int, double>{}.obs;
  late final RxInt _bytes = _files.bytes.obs;
  final Set<int> _cancelled = {};
  final RxBool _all = false.obs;
  bool _allCancelled = false;

  bool isDownloaded(int surah) => _done.contains(surah);

  /// 0..1 while [surah] is downloading, else null.
  double? progressOf(int surah) => _progress[surah];
  int get downloadedCount => _done.length;
  int get bytes => _bytes.value;

  /// Saves every file [surah]'s recitation needs ([refs], Bismillah included). Returns false
  /// when it failed (usually no connection); what was saved is kept and reused next time.
  Future<bool> download(int surah, List<AyahRef> refs) async {
    if (_progress.containsKey(surah) || isDownloaded(surah)) return true;
    _cancelled.remove(surah);
    _progress[surah] = 0;
    try {
      await _files.download(
        surah,
        refs,
        _remote,
        onProgress: (p) => _progress[surah] = p,
        cancelled: () => _cancelled.contains(surah),
      );
      if (!_cancelled.contains(surah)) _done.add(surah);
      return true;
    } on Object catch (e) {
      AppLog.w('Surah $surah download failed: ${e.runtimeType}');
      return false;
    } finally {
      _progress.remove(surah);
      _bytes.value = _files.bytes;
    }
  }

  /// True while [downloadAll] runs.
  bool get downloadingAll => _all.value;

  /// Saves every surah in [surahs] (number → its files) one after another, skipping saved
  /// ones. Returns false if it stopped on an error; [cancelAll] stops it quietly.
  Future<bool> downloadAll(Map<int, List<AyahRef>> surahs) async {
    if (_all.value) return true;
    _all.value = true;
    _allCancelled = false;
    try {
      for (final MapEntry(key: surah, value: refs) in surahs.entries) {
        if (_allCancelled) return true;
        if (!await download(surah, refs)) return _allCancelled;
      }
      return true;
    } finally {
      _all.value = false;
    }
  }

  void cancelAll() {
    _allCancelled = true;
    _progress.keys.forEach(cancel);
  }

  /// Stops after the file in flight; saved files stay for a later download.
  void cancel(int surah) => _cancelled.add(surah);

  Future<void> delete(int surah) async {
    _done.remove(surah);
    // 1:1 is also the Bismillah every other surah but At-Tawbah opens with.
    final othersNeedBismillah = _done.any((s) => s != 9);
    await _files.deleteSurah(surah, keepBismillah: surah != 1 || othersNeedBismillah);
    _bytes.value = _files.bytes;
  }

  Future<void> deleteAll() async {
    cancelAll();
    _done.clear();
    await _files.deleteAll();
    _bytes.value = 0;
  }
}
