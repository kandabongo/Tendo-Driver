import 'package:fuodz/constants/app_strings.dart';
import 'package:supercharged/supercharged.dart';

class AppTaxiSettings extends AppStrings {
  /// SHARED RIDES (additive): whether Shared Rides is enabled on the backend.
  /// Tolerant of a nested settings object (sharedRides.enabled) or a flat key.
  /// The driver shared endpoints also return `enabled`, so the UI double-gates
  /// and hides the feature when it is off (the default).
  static bool get sharedRidesEnabled => sharedRidesEnabledFrom(
        AppStrings.env('sharedRides'),
        AppStrings.env('sharedRides.enabled'),
      );

  /// Pure, testable parser for the Shared Rides flag: true when the nested
  /// {enabled:...} object or the flat key holds a truthy value. Kept separate
  /// from env()/prefs so the gating logic can be unit-tested deterministically.
  static bool sharedRidesEnabledFrom(dynamic nested, dynamic flat) {
    if (nested is Map && nested["enabled"] != null) {
      final v = nested["enabled"];
      return v == true || v == 1 || v == "1";
    }
    return flat == true || flat == 1 || flat == "1";
  }

  static bool get requiredBookingCode {
    if (AppStrings.env('taxi') == null ||
        AppStrings.env('taxi')["requestBookingCode"] == null) {
      return false;
    }
    return true;
  }

  static bool get requiredBookingCodeBeforeTrip {
    if (AppStrings.env('taxi') == null ||
        AppStrings.env('taxi')["requestBookingCode"] == null) {
      return false;
    }
    return ["both", "before"]
        .contains(AppStrings.env('taxi')["requestBookingCode"]);
  }

  static bool get requiredBookingCodeAfterTrip {
    if (AppStrings.env('taxi') == null ||
        AppStrings.env('taxi')["requestBookingCode"] == null) {
      return false;
    }
    return ["both", "after"]
        .contains(AppStrings.env('taxi')["requestBookingCode"]);
  }

  //
  static bool get showTaxiPickupInfo {
    if (AppStrings.env('taxi') == null ||
        AppStrings.env('taxi')["showTaxiPickupInfo"] == null) {
      return true;
    }

    //
    if (AppStrings.env('taxi')["showTaxiPickupInfo"] is bool) {
      return AppStrings.env('taxi')["showTaxiPickupInfo"];
    }

    //
    int value =
        AppStrings.env('taxi')["showTaxiPickupInfo"].toString().toInt() ?? 0;
    return value == 1;
  }

  static bool get showTaxiDropoffInfo {
    if (AppStrings.env('taxi') == null ||
        AppStrings.env('taxi')["showTaxiDropoffInfo"] == null) {
      return true;
    }

    //
    if (AppStrings.env('taxi')["showTaxiDropoffInfo"] is bool) {
      return AppStrings.env('taxi')["showTaxiDropoffInfo"];
    }

    //
    int value =
        AppStrings.env('taxi')["showTaxiDropoffInfo"].toString().toInt() ?? 0;
    return value == 1;
  }
}
