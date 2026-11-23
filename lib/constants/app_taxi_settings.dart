import 'package:fuodz/constants/app_strings.dart';

class AppTaxiSettings extends AppStrings {
  /// Whether Shared Rides is enabled on the backend. Tolerant of either a
  /// nested settings object (sharedRides.enabled) or a flat key. The driver
  /// shared endpoints also return `enabled`, so the UI double-gates and hides
  /// the feature when it is off (the default).
  static bool get sharedRidesEnabled {
    final nested = AppStrings.env('sharedRides');
    if (nested is Map && nested["enabled"] != null) {
      final v = nested["enabled"];
      return v == true || v == 1 || v == "1";
    }
    final flat = AppStrings.env('sharedRides.enabled');
    return flat == true || flat == 1 || flat == "1";
  }
}
