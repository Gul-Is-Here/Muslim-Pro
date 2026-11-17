import 'package:equatable/equatable.dart';
import 'package:quran_pro/data/models/prayer.dart';

/// Bundled Azan clips (see docs/AUDIO_CREDITS.md) plus the device's own notification sound.
/// The enum name is persisted and is the native resource name (`azan_<name>`): never rename one.
/// A removed value is safe: saved choices of it fall back to [fallback] when read.
enum AzanSound {
  makkah,
  madinah,
  system;

  static const AzanSound fallback = makkah;

  bool get isBundled => this != system;
  String get labelKey => 'azan_sound_$name';

  /// Android res/raw and iOS bundle resource name, without extension.
  String get resource => 'azan_$name';
  String get previewAsset => 'assets/audio/$resource.mp3';

  /// Attribution shown in the app (CC BY requires it). Details: docs/AUDIO_CREDITS.md.
  String? get credit => switch (this) {
    makkah => 'Azan from Masjid al-Haram, Makkah. Excerpt, mixed to mono, loudness-normalised.',
    madinah => 'Azan from Masjid an-Nabawi, Madinah. Excerpt, mixed to mono, loudness-normalised.',
    system => null,
  };
}

/// Per-prayer reminder choices. The master on/off switch is stored separately (SettingsService).
final class PrayerAlertSettings extends Equatable {
  const PrayerAlertSettings({this.enabled = const {}, this.sounds = const {}});

  factory PrayerAlertSettings.fromJson(Map<String, dynamic> json) {
    final enabled = (json['enabled'] as Map?)?.cast<String, dynamic>() ?? const {};
    final sounds = (json['sounds'] as Map?)?.cast<String, dynamic>() ?? const {};
    final prayers = Prayer.values.asNameMap();
    final azans = AzanSound.values.asNameMap();
    return PrayerAlertSettings(
      enabled: {
        for (final MapEntry(:key, :value) in enabled.entries)
          if (prayers[key] case final p? when value is bool) p: value,
      },
      sounds: {
        for (final MapEntry(:key, :value) in sounds.entries)
          if ((prayers[key], azans[value]) case (final p?, final s?)) p: s,
      },
    );
  }

  final Map<Prayer, bool> enabled;
  final Map<Prayer, AzanSound> sounds;

  bool isOn(Prayer p) => enabled[p] ?? true;
  AzanSound soundFor(Prayer p) => sounds[p] ?? AzanSound.fallback;

  PrayerAlertSettings withEnabled(Prayer p, {required bool on}) =>
      PrayerAlertSettings(enabled: {...enabled, p: on}, sounds: sounds);

  PrayerAlertSettings withSound(Prayer p, AzanSound sound) =>
      PrayerAlertSettings(enabled: enabled, sounds: {...sounds, p: sound});

  Map<String, dynamic> toJson() => {
    'enabled': {for (final e in enabled.entries) e.key.name: e.value},
    'sounds': {for (final e in sounds.entries) e.key.name: e.value.name},
  };

  @override
  List<Object> get props => [enabled, sounds];
}
