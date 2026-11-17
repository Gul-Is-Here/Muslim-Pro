import 'package:equatable/equatable.dart';
import 'package:quran_pro/data/models/prayer.dart';

typedef NextPrayer = ({Prayer prayer, DateTime at});

final class DayPrayerTimes extends Equatable {
  const DayPrayerTimes({required this.date, required this.times});

  final DateTime date;
  final Map<Prayer, DateTime> times;

  /// First obligatory prayer after [now] on this day, or null once Isha has passed.
  NextPrayer? nextAfter(DateTime now) {
    for (final p in Prayer.obligatory) {
      final at = times[p]!;
      if (at.isAfter(now)) return (prayer: p, at: at);
    }
    return null;
  }

  @override
  List<Object?> get props => [date, times];
}
