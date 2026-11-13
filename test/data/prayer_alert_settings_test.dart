import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/data/models/prayer_alert_settings.dart';

void main() {
  test('defaults: every prayer on, default Azan', () {
    const s = PrayerAlertSettings();
    for (final p in Prayer.obligatory) {
      expect(s.isOn(p), isTrue);
      expect(s.soundFor(p), AzanSound.fallback);
    }
  });

  test('round-trips through JSON (as persisted)', () {
    final s = const PrayerAlertSettings()
        .withEnabled(Prayer.asr, on: false)
        .withSound(Prayer.fajr, AzanSound.hamtramck)
        .withSound(Prayer.isha, AzanSound.system);
    final back = PrayerAlertSettings.fromJson(s.toJson());
    expect(back, s);
    expect(back.isOn(Prayer.asr), isFalse);
    expect(back.soundFor(Prayer.fajr), AzanSound.hamtramck);
    expect(back.soundFor(Prayer.dhuhr), AzanSound.fallback);
  });

  test('ignores unknown prayers, sounds and malformed values', () {
    final s = PrayerAlertSettings.fromJson(const {
      'enabled': {'fajr': false, 'tahajjud': false, 'dhuhr': 'yes'},
      'sounds': {'asr': 'removed_sound', 'isha': 'hamtramck', 'nope': 'tatarstan'},
    });
    expect(s.isOn(Prayer.fajr), isFalse);
    expect(s.isOn(Prayer.dhuhr), isTrue);
    expect(s.soundFor(Prayer.asr), AzanSound.fallback);
    expect(s.soundFor(Prayer.isha), AzanSound.hamtramck);
  });

  test('every bundled sound ships for preview, Android and iOS, and survives shrinking', () {
    final keep = File('android/app/src/main/res/raw/keep.xml').readAsStringSync();
    final xcode = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    for (final s in AzanSound.values.where((s) => s.isBundled)) {
      expect(File(s.previewAsset).existsSync(), isTrue, reason: s.previewAsset);
      expect(File('android/app/src/main/res/raw/${s.resource}.mp3').existsSync(), isTrue);
      expect(File('ios/Runner/${s.resource}.caf').existsSync(), isTrue);
      expect(keep, contains('@raw/${s.resource}'));
      expect(xcode, contains('${s.resource}.caf in Resources'));
      expect(s.credit, isNotNull, reason: 'attribution required in-app');
    }
  });
}
