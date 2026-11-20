import 'package:flutter/material.dart';
import 'package:fuodz/models/shared_trip.dart';
import 'package:fuodz/requests/shared_trip.request.dart';
import 'package:fuodz/view_models/base.view_model.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

/// SHARED RIDES (driver) — manage one shared trip with multiple passengers.
/// Loads the trip, then drives each passenger's state (start -> complete)
/// independently. Per-passenger busy flags prevent duplicate taps; the backend
/// is the source of truth and rejects duplicate acceptance/completion.
class SharedTripViewModel extends MyBaseViewModel {
  SharedTripViewModel(BuildContext context) {
    viewContext = context;
  }

  final SharedTripRequest _request = SharedTripRequest();

  DriverSharedTrip? trip;
  String? lastError;
  final Set<int> _busyPassengers = {};

  bool isPassengerBusy(int id) => _busyPassengers.contains(id);

  List<SharedTripPassenger> get passengers => trip?.activePassengers ?? [];

  bool get hasTrip => trip != null;

  Future<void> loadTrip() async {
    lastError = null;
    setBusy(true);
    try {
      trip = await _request.currentTrip();
    } catch (error) {
      lastError = "$error";
      setError(error);
    }
    setBusy(false);
    notifyListeners();
  }

  Future<void> acceptTrip(int tripId) async {
    setBusy(true);
    try {
      final res = await _request.acceptTrip(tripId);
      if (res.allGood) {
        toastSuccessful("Shared trip accepted".tr());
        await loadTrip();
      } else {
        toastError(res.message ?? "Could not accept trip".tr());
      }
    } catch (error) {
      toastError("$error");
    }
    setBusy(false);
  }

  Future<void> startPassenger(SharedTripPassenger p) async {
    if (isPassengerBusy(p.id)) return;
    _busyPassengers.add(p.id);
    notifyListeners();
    try {
      final res = await _request.startPassenger(p.id);
      if (res.allGood) {
        toastSuccessful("Passenger onboard".tr());
        await loadTrip();
      } else {
        toastError(res.message ?? "Could not start".tr());
      }
    } catch (error) {
      toastError("$error");
    }
    _busyPassengers.remove(p.id);
    notifyListeners();
  }

  Future<void> completePassenger(SharedTripPassenger p) async {
    if (isPassengerBusy(p.id)) return;
    _busyPassengers.add(p.id);
    notifyListeners();
    try {
      final res = await _request.completePassenger(p.id);
      if (res.allGood) {
        toastSuccessful("Passenger journey completed".tr());
        await loadTrip();
      } else {
        toastError(res.message ?? "Could not complete".tr());
      }
    } catch (error) {
      toastError("$error");
    }
    _busyPassengers.remove(p.id);
    notifyListeners();
  }

  void retry() => loadTrip();
}
