import 'package:flutter_test/flutter_test.dart';
import 'package:fuodz/constants/api.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/constants/app_taxi_settings.dart';

/// SHARED RIDES (driver) — the feature flag that gates the "Shared Trip" entry
/// on the taxi dashboard (rendered only `if (AppTaxiSettings.sharedRidesEnabled)`).
/// Also guards that the existing taxi settings members were NOT clobbered.
void main() {
  group('Shared Rides flag gates the driver Shared Trip entry', () {
    tearDown(() => AppStrings.appSettingsObject = null);

    test('disabled when no app settings -> entry hidden', () {
      AppStrings.appSettingsObject = null;
      expect(AppTaxiSettings.sharedRidesEnabled, isFalse);
    });

    test('enabled via nested boolean -> entry visible', () {
      AppStrings.appSettingsObject = {
        "sharedRides": {"enabled": true}
      };
      expect(AppTaxiSettings.sharedRidesEnabled, isTrue);
    });

    test('enabled via flat "1"', () {
      AppStrings.appSettingsObject = {"sharedRides.enabled": "1"};
      expect(AppTaxiSettings.sharedRidesEnabled, isTrue);
    });

    test('existing taxi settings still work (regression guard)', () {
      AppStrings.appSettingsObject = {
        "taxi": {"requestBookingCode": "both"}
      };
      expect(AppTaxiSettings.requiredBookingCode, isTrue);
      expect(AppTaxiSettings.requiredBookingCodeBeforeTrip, isTrue);
      expect(AppTaxiSettings.requiredBookingCodeAfterTrip, isTrue);
      expect(AppTaxiSettings.showTaxiPickupInfo, isTrue);
      expect(AppTaxiSettings.showTaxiDropoffInfo, isTrue);
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
