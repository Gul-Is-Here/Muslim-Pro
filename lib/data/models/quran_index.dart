final class SurahInfo {
  const SurahInfo({
    required this.number,
    required this.arabic,
    required this.name,
    required this.meaning,
    required this.ayahs,
    required this.makki,
  });

  factory SurahInfo.fromJson(Map<String, dynamic> j) => SurahInfo(
    number: j['n'] as int,
    arabic: j['ar'] as String,
    name: j['name'] as String,
    meaning: j['meaning'] as String,
    ayahs: j['ayahs'] as int,
    makki: j['makki'] as bool,
  );

  final int number;
  final String arabic;
  final String name;
  final String meaning;
  final int ayahs;

  /// Revealed in Makkah (else Madinah).
  final bool makki;
}

final class JuzInfo {
  const JuzInfo({
    required this.number,
    required this.surah,
    required this.ayah,
    required this.name,
    required this.arabic,
  });

  factory JuzInfo.fromJson(Map<String, dynamic> j) => JuzInfo(
    number: j['n'] as int,
    surah: j['surah'] as int,
    ayah: j['ayah'] as int,
    name: j['name'] as String,
    arabic: j['ar'] as String,
  );

  final int number;

  /// Where this juz starts.
  final int surah;
  final int ayah;

  /// Traditional name: the juz's opening words.
  final String name;
  final String arabic;
}

final class QuranIndex {
  const QuranIndex(this.surahs, this.juz);

  factory QuranIndex.fromJson(Map<String, dynamic> j) => QuranIndex(
    [for (final s in j['surahs'] as List<dynamic>) SurahInfo.fromJson(s as Map<String, dynamic>)],
    [for (final z in j['juz'] as List<dynamic>) JuzInfo.fromJson(z as Map<String, dynamic>)],
  );

  final List<SurahInfo> surahs;
  final List<JuzInfo> juz;

  SurahInfo surah(int number) => surahs[number - 1];
}

/// One surah's text: Uthmani Arabic (Bismillah not prefixed to ayah 1) and its translations.
final class SurahText {
  const SurahText({
    required this.arabic,
    required this.english,
    required this.urdu,
    required this.juz,
    required this.sajda,
  });

  factory SurahText.fromJson(Map<String, dynamic> j) {
    List<String> strings(String k) => [for (final s in j[k] as List<dynamic>) s as String];
    return SurahText(
      arabic: strings('ar'),
      english: strings('en'),
      urdu: strings('ur'),
      juz: [for (final n in j['juz'] as List<dynamic>) n as int],
      sajda: {for (final n in j['sajda'] as List<dynamic>) n as int},
    );
  }

  final List<String> arabic;
  final List<String> english;
  final List<String> urdu;

  /// Juz of each ayah (index 0 = ayah 1).
  final List<int> juz;

  /// Ayah numbers carrying a prostration of recitation.
  final Set<int> sajda;

  int get length => arabic.length;
}

/// The reader's place in the Quran.
typedef AyahRef = ({int surah, int ayah});
