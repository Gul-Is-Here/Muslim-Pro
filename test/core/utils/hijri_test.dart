import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/core/utils/hijri.dart';

void main() {
  test('toGregorian inverts fromGregorian for every day across ~20 years', () {
    var d = DateTime(2015);
    final end = DateTime(2035);
    while (d.isBefore(end)) {
      final h = Hijri.fromGregorian(d);
      expect(Hijri.toGregorian(h.year, h.month, h.day), d, reason: '$h');
      d = DateTime(d.year, d.month, d.day + 1);
    }
  });

  test('Ramadan has 30 days in the tabular calendar', () {
    expect(Hijri.monthLength(1448, 9), 30);
    expect(Hijri.monthLength(1448, 10), 29);
  });
}
