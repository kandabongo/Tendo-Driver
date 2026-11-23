import 'package:flutter_test/flutter_test.dart';
import 'package:fuodz/constants/api.dart';
import 'package:fuodz/constants/app_taxi_settings.dart';

/// SHARED RIDES (driver) — the feature flag that gates the "Shared Trip" entry
/// on the taxi dashboard (rendered only `if (AppTaxiSettings.sharedRidesEnabled)`,
/// which delegates to the pure parser below). OFF unless the backend enables it.
/// NB: the existing taxi settings members (requiredBookingCode*/showTaxi*Info)
/// are guaranteed to exist by compilation — the app build references them.
void main() {
  group('Shared Rides flag parser gates the driver Shared Trip entry', () {
    test('absent (both null) -> hidden', () {
      expect(AppTaxiSettings.sharedRidesEnabledFrom(null, null), isFalse);
    });

    test('env default empty strings -> hidden', () {
      expect(AppTaxiSettings.sharedRidesEnabledFrom("", ""), isFalse);
    });

    test('nested {enabled:true} -> visible', () {
      expect(
          AppTaxiSettings.sharedRidesEnabledFrom({"enabled": true}, null), isTrue);
    });

    test('nested {enabled:"1"} -> visible', () {
      expect(
          AppTaxiSettings.sharedRidesEnabledFrom({"enabled": "1"}, null), isTrue);
    });

    test('nested {enabled:false} -> hidden', () {
      expect(AppTaxiSettings.sharedRidesEnabledFrom({"enabled": false}, null),
          isFalse);
    });

    test('flat "1" -> visible', () {
      expect(AppTaxiSettings.sharedRidesEnabledFrom(null, "1"), isTrue);
    });
  });

  group('Driver shared endpoints map to the backend routes', () {
    test('current-trip / trip / passenger paths', () {
      expect(Api.sharedRideCurrentTrip, "/taxi/shared/trip/current");
      expect(Api.sharedRideTrip, "/taxi/shared/trip");
      expect(Api.sharedRidePassenger, "/taxi/shared/passenger");
    });
  });
}
