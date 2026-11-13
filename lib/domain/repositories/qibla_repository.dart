import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/models/user_location.dart';

/// `bearing`: degrees clockwise from true north; `declination`: east-positive, degrees.
/// The Kaaba, as used by adhan's Qibla calculation.
const kaabaLocation = UserLocation(21.4225241, 39.8261818);

typedef QiblaInfo = ({double bearing, double distanceKm, double declination});

abstract interface class QiblaRepository {
  Result<QiblaInfo> infoFor(UserLocation at, DateTime when);
}
