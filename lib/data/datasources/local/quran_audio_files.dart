import 'dart:io';

import 'package:quran_pro/data/models/quran_index.dart';

/// Downloads one ayah's audio; injectable so tests need no network.
typedef FetchBytes = Future<List<int>> Function(Uri url);

/// Recitation files kept on the device for offline play: `<root>/SSSAAA.mp3`, the same names
/// EveryAyah uses, plus `SSS.done` once a whole surah is saved.
final class QuranAudioFiles {
  QuranAudioFiles(this.root, {FetchBytes? fetch}) : _fetch = fetch ?? _httpGet;

  final Directory root;
  final FetchBytes _fetch;

  static String _three(int n) => n.toString().padLeft(3, '0');

  File file(int surah, int ayah) => File('${root.path}/${_three(surah)}${_three(ayah)}.mp3');
  File _marker(int surah) => File('${root.path}/${_three(surah)}.done');

  bool has(int surah, int ayah) => file(surah, ayah).existsSync();

  /// Surahs saved completely (a cancelled or failed download leaves no marker).
  Set<int> completeSurahs() {
    if (!root.existsSync()) return {};
    return {
      for (final f in root.listSync().whereType<File>())
        if (f.path.endsWith('.done')) ?int.tryParse(f.uri.pathSegments.last.split('.').first),
    };
  }

  /// Saves every ayah in [refs] that is not on the device yet, then marks [surah] complete.
  /// [onProgress] gets 0..1; returning true from [cancelled] stops between files.
  /// Throws on a network or HTTP error; files already saved are kept for the next attempt.
  Future<void> download(
    int surah,
    List<AyahRef> refs,
    Uri Function(int surah, int ayah) remote, {
    void Function(double done)? onProgress,
    bool Function()? cancelled,
  }) async {
    root.createSync(recursive: true);
    for (final (i, r) in refs.indexed) {
      if (cancelled?.call() ?? false) return;
      final target = file(r.surah, r.ayah);
      if (!target.existsSync()) {
        final bytes = await _fetch(remote(r.surah, r.ayah));
        // Write beside, then rename: a half-written file never looks downloaded.
        final part = File('${target.path}.part');
        await part.writeAsBytes(bytes, flush: true);
        await part.rename(target.path);
      }
      onProgress?.call((i + 1) / refs.length);
    }
    if (cancelled?.call() ?? false) return;
    await _marker(surah).writeAsString('');
  }

  /// Removes [surah]'s files. 1:1 (the Bismillah other surahs open with) stays unless
  /// [keepBismillah] is false.
  Future<void> deleteSurah(int surah, {bool keepBismillah = true}) async {
    if (!root.existsSync()) return;
    final prefix = _three(surah);
    for (final f in root.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (!name.startsWith(prefix)) continue;
      if (keepBismillah && name == '001001.mp3') continue;
      await f.delete();
    }
  }

  Future<void> deleteAll() async {
    if (root.existsSync()) await root.delete(recursive: true);
  }

  int get bytes => root.existsSync()
      ? root.listSync().whereType<File>().fold(0, (sum, f) => sum + f.lengthSync())
      : 0;

  static Future<List<int>> _httpGet(Uri url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final response = await (await client.getUrl(url))
          .close()
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: url);
      }
      return [for (final chunk in await response.toList()) ...chunk];
    } finally {
      client.close();
    }
  }
}
