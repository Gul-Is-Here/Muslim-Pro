import 'package:equatable/equatable.dart';
import 'package:quran_pro/data/models/prayer.dart';

/// Bundled Azan clips (see docs/AUDIO_CREDITS.md) plus the device's own notification sound.
/// The enum name is persisted and is the native resource name (`azan_<name>`): never rename one.
enum AzanSound {
  tatarstan,
  hamtramck,
  system;

  static const AzanSound fallback = tatarstan;

  bool get isBundled => this != system;
  String get labelKey => 'azan_sound_$name';

  /// Android res/raw and iOS bundle resource name, without extension.
  String get resource => 'azan_$name';
  String get previewAsset => 'assets/audio/$resource.mp3';

  /// Attribution shown in the app (CC BY requires it). Details: docs/AUDIO_CREDITS.md.
  String? get credit => switch (this) {
    tatarstan =>
      '“morning_azan.wav” by Jahffar, freesound.org/s/168775 — CC0 1.0. '
          'Excerpt, mixed to mono, loudness-normalised.',
    hamtramck =>
      '“Islamic Call to Prayer (Dhuhr Adhan Audiophile Field Recording from Hamtramck, MI '
          '96 kHz 24 Bit Stereo).wav” by RJStefanski, freesound.org/s/255231 — '
          'CC BY 3.0 (creativecommons.org/licenses/by/3.0). Excerpt, mixed to mono, '
          'loudness-normalised.',
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
