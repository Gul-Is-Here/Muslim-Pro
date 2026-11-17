/// One dhikr from Hisn al-Muslim, numbered as in the book.
final class Dhikr {
  const Dhikr({
    required this.number,
    required this.arabic,
    required this.translit,
    required this.english,
    required this.repeat,
    required this.hasAudio,
    required this.start,
  });

  factory Dhikr.fromJson(Map<String, dynamic> j) => Dhikr(
    number: j['n'] as int,
    arabic: j['ar'] as String,
    translit: j['tr'] as String,
    english: j['en'] as String,
    repeat: j['repeat'] as int,
    hasAudio: j['audio'] as bool,
    start: Duration(milliseconds: ((j['start'] as num) * 1000).round()),
  );

  final int number;
  final String arabic;
  final String translit;
  final String english;

  /// Times to say it.
  final int repeat;
  final bool hasAudio;

  /// Where the recitation begins in the recording (after a spoken chapter title).
  final Duration start;

  Uri get audioUrl => Uri.parse('https://www.hisnmuslim.com/audio/ar/$number.mp3');
}

enum AdhkarCategory { morningEvening, afterSalah, sleep, waking }

final class AdhkarBook {
  const AdhkarBook(this.categories);

  factory AdhkarBook.fromJson(Map<String, dynamic> j) {
    const ids = {
      'morning_evening': AdhkarCategory.morningEvening,
      'after_salah': AdhkarCategory.afterSalah,
      'sleep': AdhkarCategory.sleep,
      'waking': AdhkarCategory.waking,
    };
    final categories = <AdhkarCategory, List<Dhikr>>{};
    for (final c in (j['categories'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      final id = ids[c['id']];
      if (id == null) continue; // a category this app version does not show
      categories[id] = [
        for (final d in c['items'] as List<dynamic>) Dhikr.fromJson(d as Map<String, dynamic>),
      ];
    }
    return AdhkarBook(categories);
  }

  final Map<AdhkarCategory, List<Dhikr>> categories;

  List<Dhikr> of(AdhkarCategory c) => categories[c] ?? const [];
}
