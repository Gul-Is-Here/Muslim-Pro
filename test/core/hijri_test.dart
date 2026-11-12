import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/core/utils/hijri.dart';

void main() {
  test('converts known dates (Ramadan 1446 began 1 March 2025)', () {
    expect(Hijri.fromGregorian(DateTime(2025, 3)), (year: 1446, month: 9, day: 1));
    expect(Hijri.fromGregorian(DateTime(2025, 3, 14)), (year: 1446, month: 9, day: 14));
    expect(Hijri.fromGregorian(DateTime(2025, 3, 31)), (year: 1446, month: 10, day: 1));
  });
}
