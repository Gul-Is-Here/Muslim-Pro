enum Prayer {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha;

  static const List<Prayer> obligatory = [fajr, dhuhr, asr, maghrib, isha];
  String get labelKey => 'prayer_$name';
}
