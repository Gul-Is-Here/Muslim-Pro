typedef HijriDate = ({int year, int month, int day});

/// Tabular (civil) Islamic calendar conversion.
// shortcut: arithmetic calendar can differ ±1 day from local moon sighting; add a user day-offset
// setting when users report it.
abstract final class Hijri {
  static HijriDate fromGregorian(DateTime date) {
    final jd =
        DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(1970)).inDays +
        2440588; // Julian day number
    var l = jd - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) + (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) - (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
    final month = (24 * l) ~/ 709;
    return (year: 30 * n + j - 30, month: month, day: l - (709 * month) ~/ 24);
  }

  /// Gregorian date of a tabular Hijri date (inverse of [fromGregorian]).
  static DateTime toGregorian(int year, int month, int day) {
    final jd =
        day + (29.5 * (month - 1)).ceil() + (year - 1) * 354 + (3 + 11 * year) ~/ 30 + 1948439;
    final g = DateTime.utc(1970).add(Duration(days: jd - 2440588));
    return DateTime(g.year, g.month, g.day);
  }

  /// Days in a tabular Hijri month: odd months 30, even 29, Dhu al-Hijjah 30 in leap years.
  static int monthLength(int year, int month) => toGregorian(
    month == 12 ? year + 1 : year,
    month == 12 ? 1 : month + 1,
    1,
  ).difference(toGregorian(year, month, 1)).inDays;
}
