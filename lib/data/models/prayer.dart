enum Prayer {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha;

  static const List<Prayer> obligatory = [fajr, dhuhr, asr, maghrib, isha];
  String get labelKey => 'prayer_$name';

  /// Shown under the translated name in every language.
  String get arabicName => switch (this) {
    fajr => 'الفجر',
    sunrise => 'الشروق',
    dhuhr => 'الظهر',
    asr => 'العصر',
    maghrib => 'المغرب',
    isha => 'العشاء',
  };
}
