import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/core/localization/app_translations.dart';

void main() {
  test('every locale defines exactly the same keys', () {
    final all = AppTranslations().keys;
    final base = all['en_US']!.keys.toSet();
    for (final entry in all.entries) {
      expect(entry.value.keys.toSet(), base, reason: entry.key);
    }
  });
}
