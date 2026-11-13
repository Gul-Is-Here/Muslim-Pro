import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/data/models/prayer_settings.dart';
import 'package:quran_pro/data/models/saved_place.dart';
import 'package:quran_pro/data/models/user_location.dart';

void main() {
  test('country picks the local convention; unknown countries get MWL', () {
    expect(
      PrayerSettings.forCountry('PK'),
      const PrayerSettings(method: 'karachi', hanafiAsr: true),
    );
    expect(
      PrayerSettings.forCountry('pk'),
      const PrayerSettings(method: 'karachi', hanafiAsr: true),
    );
    expect(PrayerSettings.forCountry('SA'), const PrayerSettings(method: 'umm_al_qura'));
    expect(PrayerSettings.forCountry('GB'), const PrayerSettings());
    expect(PrayerSettings.forCountry(null), const PrayerSettings());
  });

  test('every default method exists in adhan', () {
    const adhanMethods = {
      'muslim_world_league',
      'egyptian',
      'karachi',
      'umm_al_qura',
      'dubai',
      'moon_sighting_committee', //
      'north_america', 'kuwait', 'qatar', 'singapore', 'turkey', 'tehran', 'other',
    };
    for (final c in [
      'PK',
      'IN',
      'BD',
      'AF',
      'SA',
      'AE',
      'KW',
      'QA',
      'EG',
      'TR',
      'IR',
      'SG',
      'MY',
      'ID',
      'BN',
      'US',
      'CA',
      'XX',
    ]) {
      expect(adhanMethods, contains(PrayerSettings.forCountry(c).method), reason: c);
    }
  });

  test('time zone gives an offline country guess', () {
    expect(countryForTimeZone('Asia/Karachi'), 'PK');
    expect(countryForTimeZone('Asia/Calcutta'), 'IN');
    expect(countryForTimeZone('Europe/London'), isNull);
    expect(countryForTimeZone(null), isNull);
  });

  test('a cached place name only describes locations within ~5 km', () {
    const place = SavedPlace(at: UserLocation(30.08, 72.55), name: 'Burewala', countryCode: 'PK');
    expect(place.describes(const UserLocation(30.10, 72.57)), isTrue);
    expect(place.describes(const UserLocation(31.52, 74.36)), isFalse); // Lahore
    expect(SavedPlace.fromJson(place.toJson()), place);
  });
}
