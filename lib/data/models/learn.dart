/// Text in several languages (`en` always present). Arabic UI falls back to English prose;
/// Quranic and du'a text is carried separately in `arabic`.
typedef L10nText = Map<String, String>;

String pick(L10nText t, String lang) => t[lang] ?? t['en'] ?? '';

L10nText _text(Object? v) => switch (v) {
  final String s => {'en': s}, // language-neutral (Arabic, transliteration, numbers)
  final Map<dynamic, dynamic> m => {
    for (final MapEntry(:key, :value) in m.entries)
      if (key is String && value is String) key: value,
  },
  _ => const {},
};

/// A teaching card: Arabic text (optional), transliteration, explanation and source.
final class LearnCard {
  const LearnCard({
    required this.title,
    required this.body,
    this.arabic,
    this.translit,
    this.ref,
    this.audio,
  });

  factory LearnCard.fromJson(Map<String, dynamic> j) => LearnCard(
    title: _text(j['title']),
    body: _text(j['body']),
    arabic: j['arabic'] as String?,
    translit: j['translit'] as String?,
    ref: j['ref'] as String?,
    audio: j['audio'] as String?,
  );

  final L10nText title;
  final L10nText body;
  final String? arabic;
  final String? translit;
  final String? ref;

  /// Bundled asset path (e.g. a Qaida letter's name), played on tap.
  final String? audio;
}

/// Multiple choice; [answer] indexes [options] as authored (the UI shuffles).
final class LearnQuestion {
  const LearnQuestion({
    required this.prompt,
    required this.options,
    required this.answer,
    this.arabic,
  });

  factory LearnQuestion.fromJson(Map<String, dynamic> j) => LearnQuestion(
    prompt: _text(j['prompt']),
    options: [for (final o in j['options'] as List<dynamic>) _text(o)],
    answer: j['answer'] as int,
    arabic: j['arabic'] as String?,
  );

  final L10nText prompt;
  final List<L10nText> options;
  final int answer;
  final String? arabic;
}

final class LearnLesson {
  const LearnLesson({
    required this.id,
    required this.title,
    required this.xp,
    required this.cards,
    required this.questions,
  });

  factory LearnLesson.fromJson(Map<String, dynamic> j) => LearnLesson(
    id: j['id'] as String,
    title: _text(j['title']),
    xp: j['xp'] as int,
    cards: [
      for (final c in j['cards'] as List<dynamic>) LearnCard.fromJson(c as Map<String, dynamic>),
    ],
    questions: [
      for (final q in j['questions'] as List<dynamic>)
        LearnQuestion.fromJson(q as Map<String, dynamic>),
    ],
  );

  final String id;
  final L10nText title;
  final int xp;
  final List<LearnCard> cards;
  final List<LearnQuestion> questions;
}

final class LearnUnit {
  const LearnUnit({
    required this.id,
    required this.icon,
    required this.kids,
    required this.title,
    required this.tag,
    required this.lessons,
  });

  factory LearnUnit.fromJson(Map<String, dynamic> j) => LearnUnit(
    id: j['id'] as String,
    icon: j['icon'] as String,
    kids: j['kids'] == true,
    title: _text(j['title']),
    tag: _text(j['tag']),
    lessons: [
      for (final l in j['lessons'] as List<dynamic>)
        LearnLesson.fromJson(l as Map<String, dynamic>),
    ],
  );

  final String id;
  final String icon;
  final bool kids;
  final L10nText title;
  final L10nText tag;
  final List<LearnLesson> lessons;
}

final class Curriculum {
  const Curriculum(this.units);

  factory Curriculum.fromJson(Map<String, dynamic> j) => Curriculum([
    for (final u in j['units'] as List<dynamic>) LearnUnit.fromJson(u as Map<String, dynamic>),
  ]);

  final List<LearnUnit> units;

  LearnLesson? lesson(String id) {
    for (final u in units) {
      for (final l in u.lessons) {
        if (l.id == id) return l;
      }
    }
    return null;
  }

  LearnUnit? unitOf(String lessonId) {
    for (final u in units) {
      if (u.lessons.any((l) => l.id == lessonId)) return u;
    }
    return null;
  }
}

enum UnitStatus { done, active, locked }

/// Units unlock in order: each needs the one before it (within [units]) finished.
List<UnitStatus> unitStatuses(List<LearnUnit> units, Set<String> completed) {
  var open = true;
  return [
    for (final u in units)
      () {
        final done = u.lessons.every((l) => completed.contains(l.id));
        final s = done ? UnitStatus.done : (open ? UnitStatus.active : UnitStatus.locked);
        if (!done) open = false;
        return s;
      }(),
  ];
}
