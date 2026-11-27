import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_images.dart';
import 'package:fuodz/models/shared_trip.dart';
import 'package:fuodz/requests/shared_trip.request.dart';
import 'package:fuodz/services/alert.service.dart';
import 'package:fuodz/services/location.service.dart';
import 'package:fuodz/view_models/base.view_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Greedy nearest-neighbour ordering of stops from a starting position. A
/// convenience for the driver; the backend never relies on this sequence.
/// Pure + deterministic, so it is unit-tested directly. Returns the input order
/// unchanged when there is no origin or fewer than two stops.
List<SharedStop> orderStopsNearestFrom(List<SharedStop> stops, LatLng? from) {
  if (from == null || stops.length < 2) return stops;
  final remaining = [...stops];
  final ordered = <SharedStop>[];
  LatLng cursor = from;
  while (remaining.isNotEmpty) {
    remaining.sort((a, b) =>
        _kmBetween(cursor, a.latLng).compareTo(_kmBetween(cursor, b.latLng)));
    final next = remaining.removeAt(0);
    ordered.add(next);
    cursor = next.latLng;
  }
  return ordered;
}

double _kmBetween(LatLng a, LatLng b) {
  const r = 6371.0;
  final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
  final dLng = (b.longitude - a.longitude) * math.pi / 180.0;
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(a.latitude * math.pi / 180.0) *
          math.cos(b.latitude * math.pi / 180.0) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}

/// A provisional navigation stop derived from a passenger's leg. Display-only:
/// it NEVER changes server-authoritative lifecycle state. A pickup stop is shown
/// for a passenger still awaiting pickup; a drop-off stop for an onboard one.
class SharedStop {
  final int passengerId;
  final String type; // "pickup" | "dropoff"
  final String label;
  final double lat;
  final double lng;
  SharedStop({
    required this.passengerId,
    required this.type,
    required this.label,
    required this.lat,
    required this.lng,
  });
  LatLng get latLng => LatLng(lat, lng);
  bool get isPickup => type == "pickup";
}

/// SHARED RIDES (driver) — manage one shared trip with multiple passengers.
/// Loads the trip, then drives each passenger's state (start -> complete)
/// independently. Per-passenger busy flags prevent duplicate taps; the backend
/// is the source of truth and rejects duplicate acceptance/completion.
///
/// This view model also powers the dedicated navigation screen: a live map with
/// the driver's own position, every passenger's pickup + drop-off, and a
/// provisional nearest-next ordering of the remaining stops. The ordering and
/// the map are purely a driver aid — all state transitions remain server-side.
class SharedTripViewModel extends MyBaseViewModel {
  SharedTripViewModel(BuildContext context) {
    viewContext = context;
  }

  final SharedTripRequest _request = SharedTripRequest();

  DriverSharedTrip? trip;
  String? lastError;
  final Set<int> _busyPassengers = {};

  // navigation / map state
  GoogleMapController? mapController;
  Set<Marker> mapMarkers = {};
  LatLng? driverLatLng;
  List<SharedStop> orderedStops = [];
  StreamSubscription<Position>? _locStream;
  // Poll the active trip so a passenger pooled on mid-journey (a new offer)
  // surfaces live even without a push. Stopped on dispose.
  Timer? _pollTimer;

  bool isPassengerBusy(int id) => _busyPassengers.contains(id);

  List<SharedTripPassenger> get passengers => trip?.activePassengers ?? [];

  /// Pooled passengers awaiting this driver's accept/decline right now.
  List<SharedTripPassenger> get pendingOffers =>
      passengers.where((p) => p.isPendingPooledOffer).toList();

  bool get hasTrip => trip != null;

  SharedStop? get nextStop => orderedStops.isNotEmpty ? orderedStops.first : null;

  /// True while we are still retrying a just-opened screen that has not yet seen
  /// its trip (e.g. immediately after accept). The page shows a connecting state
  /// rather than the "no active trip" empty state during this window.
  bool get isResolvingTrip =>
      trip == null && lastError == null && _emptyRetries < _maxEmptyRetries;

  /// Seed the driver's position and subscribe to live updates. Safe to call once.
  // Set once the view model is disposed, so async callbacks (the location
  // stream, the retry timer) never touch a disposed GoogleMapController or call
  // notifyListeners() after teardown — the source of the
  // "GoogleMapController ... used after ... disposed" error.
  bool _disposed = false;

  void initNavigation() {
    final pos = LocationService().currentLocationData;
    if (pos != null) {
      driverLatLng = LatLng(pos.latitude, pos.longitude);
    }
    _locStream ??= LocationService().getNewLocationStream().listen((p) {
      if (_disposed) return;
      driverLatLng = LatLng(p.latitude, p.longitude);
      _rebuildStopsAndMarkers();
      _updateDriverMarker();
      if (!_disposed) notifyListeners();
    });
    // Live refresh so a passenger pooled on mid-trip appears as a new offer
    // without the driver manually pulling to refresh. Lightweight read-only poll.
    _pollTimer ??= Timer.periodic(const Duration(seconds: 12), (_) {
      if (_disposed || !hasTrip) return;
      _refreshTripSilently();
    });
  }

  /// A quiet reload (no spinner) used by the poll so the UI doesn't flicker.
  Future<void> _refreshTripSilently() async {
    try {
      final latest = await _request.currentTrip();
      if (_disposed) return;
      trip = latest;
      _rebuildStopsAndMarkers();
      await _rebuildAllMarkers();
      if (!_disposed) notifyListeners();
    } catch (_) {
      // transient — keep last good state, the next tick retries
    }
  }

  void setMapController(GoogleMapController c) {
    if (_disposed) return;
    mapController = c;
    _fitCamera();
  }

  // Guards the "order disappeared after acceptance" case: when the screen opens
  // right after accept, a read replica can momentarily return no trip. Rather
  // than drop straight to the bleak empty state, retry a couple of times before
  // concluding there is genuinely no active trip.
  int _emptyRetries = 0;
  static const int _maxEmptyRetries = 3;

  Future<void> loadTrip() async {
    lastError = null;
    setBusy(true);
    try {
      trip = await _request.currentTrip();
    } catch (error) {
      lastError = "$error";
      setError(error);
    }
    if (_disposed) return;
    setBusy(false);
    _rebuildStopsAndMarkers();
    await _rebuildAllMarkers();
    if (_disposed) return;
    notifyListeners();
    _fitCamera();

    // Transient-empty retry: no error, but no trip yet -> try again shortly.
    if (trip == null && lastError == null && _emptyRetries < _maxEmptyRetries) {
      _emptyRetries++;
      await Future.delayed(const Duration(seconds: 2));
      if (_disposed) return;
      if (trip == null) {
        await loadTrip();
      }
    } else if (trip != null) {
      _emptyRetries = 0; // reset once a trip is in hand
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _locStream?.cancel();
    _pollTimer?.cancel();
    mapController = null;
    super.dispose();
  }

  // ---- provisional nearest-next ordering (display only) -----------------
  void _rebuildStopsAndMarkers() {
    final stops = <SharedStop>[];
    for (final p in passengers) {
      if (p.isDropped) continue;
      // A pooled passenger not yet accepted is an offer, not a stop — never
      // route to someone the driver hasn't accepted.
      if (p.isPendingPooledOffer) continue;
      if (p.isOnboard) {
        if (p.dropoffLatitude != null && p.dropoffLongitude != null) {
          stops.add(SharedStop(
            passengerId: p.id,
            type: "dropoff",
            label: p.passengerName ?? "Passenger",
            lat: p.dropoffLatitude!,
            lng: p.dropoffLongitude!,
          ));
        }
      } else {
        if (p.pickupLatitude != null && p.pickupLongitude != null) {
          stops.add(SharedStop(
            passengerId: p.id,
            type: "pickup",
            label: p.passengerName ?? "Passenger",
            lat: p.pickupLatitude!,
            lng: p.pickupLongitude!,
          ));
        }
      }
    }
    orderedStops = orderStopsNearestFrom(stops, driverLatLng);
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

  /// Driver ACCEPTS a pooled passenger offered onto the active trip
  /// (offered -> accepted). The route/stop list recalculates on reload.
  Future<void> acceptPassenger(SharedTripPassenger p) async {
    if (isPassengerBusy(p.id)) return;
    _busyPassengers.add(p.id);
    notifyListeners();
    try {
      final res = await _request.acceptPassenger(p.id);
      if (res.allGood) {
        toastSuccessful("Passenger added to your trip".tr());
        await loadTrip();
      } else {
        toastError(res.message ?? "Could not accept passenger".tr());
      }
    } catch (error) {
      toastError("$error");
    }
    _busyPassengers.remove(p.id);
    notifyListeners();
  }

  /// Driver DECLINES a pooled passenger — frees the seat; the trip continues.
  Future<void> declinePassenger(SharedTripPassenger p) async {
    if (isPassengerBusy(p.id)) return;
    _busyPassengers.add(p.id);
    notifyListeners();
    try {
      final res = await _request.declinePassenger(p.id);
      if (res.allGood) {
        toastSuccessful("Passenger declined".tr());
        await loadTrip();
      } else {
        toastError(res.message ?? "Could not decline".tr());
      }
    } catch (error) {
      toastError("$error");
    }
    _busyPassengers.remove(p.id);
    notifyListeners();
  }

  /// Driver cancels ONE already-accepted passenger without ending the trip.
  Future<void> cancelOnePassenger(SharedTripPassenger p) async {
    if (isPassengerBusy(p.id)) return;
    await AlertService.confirm(
      title: "Cancel this passenger?".tr(),
      text: "This cancels only this passenger. Your other passengers continue."
          .tr(),
      confirmBtnText: "Yes, cancel".tr(),
      onConfirm: () => _doCancelOnePassenger(p),
    );
  }

  Future<void> _doCancelOnePassenger(SharedTripPassenger p) async {
    if (isPassengerBusy(p.id)) return;
    _busyPassengers.add(p.id);
    notifyListeners();
    try {
      final res = await _request.cancelOnePassenger(p.id);
      if (res.allGood) {
        toastSuccessful("Passenger cancelled".tr());
        // If that was the last passenger the backend closes the trip; reloading
        // reflects whichever state we're now in.
        final closed = (res.body is Map) && (res.body["trip_closed"] == true);
        if (closed && !_disposed) {
          Navigator.of(viewContext).pop();
        } else {
          await loadTrip();
        }
      } else {
        toastError(res.message ?? "Could not cancel passenger".tr());
      }
    } catch (error) {
      toastError("$error");
    }
    _busyPassengers.remove(p.id);
    notifyListeners();
  }

  // Client-side "arrived at pickup" markers. Shared rides have no server
  // 'arrived' status (the server lifecycle is accepted -> en_route -> onboard ->
  // dropped), so Arrived is a local UI step between En route and Start. It never
  // changes server state.
  final Set<int> _arrivedPassengers = {};
  bool isArrived(int id) => _arrivedPassengers.contains(id);
  void markArrived(SharedTripPassenger p) {
    _arrivedPassengers.add(p.id);
    notifyListeners();
  }

  Future<void> enRoutePassenger(SharedTripPassenger p) async {
    if (isPassengerBusy(p.id)) return;
    _busyPassengers.add(p.id);
    notifyListeners();
    try {
      final res = await _request.enRoutePassenger(p.id);
      if (res.allGood) {
        toastSuccessful("On your way to pickup".tr());
        await loadTrip();
      } else {
        toastError(res.message ?? "Could not update".tr());
      }
    } catch (error) {
      toastError("$error");
    }
    _busyPassengers.remove(p.id);
    notifyListeners();
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

  bool cancelling = false;

  /// Driver cancels the whole accepted trip (cannot continue). Server cancels
  /// every active passenger + their orders and marks the trip cancelled.
  Future<void> cancelTrip() async {
    final t = trip;
    if (t == null || cancelling) return;
    await AlertService.confirm(
      title: "Cancel trip?".tr(),
      text: "This cancels the shared trip for all passengers. Continue?".tr(),
      confirmBtnText: "Yes, cancel".tr(),
      onConfirm: () => _doCancelTrip(t.id),
    );
  }

  Future<void> _doCancelTrip(int tripId) async {
    if (cancelling) return;
    cancelling = true;
    notifyListeners();
    try {
      final res = await _request.driverCancelTrip(tripId);
      if (res.allGood) {
        toastSuccessful("Trip cancelled".tr());
        if (!_disposed) Navigator.of(viewContext).pop();
      } else {
        toastError(res.message ?? "Could not cancel".tr());
      }
    } catch (error) {
      toastError("$error");
    }
    cancelling = false;
    if (!_disposed) notifyListeners();
  }

  // ---- markers ----------------------------------------------------------
  Future<void> _rebuildAllMarkers() async {
    final markers = <Marker>{};
    final pickupIcon = await _icon(AppImages.pickupLocation);
    final dropoffIcon = await _icon(AppImages.dropoffLocation);
    for (final p in passengers) {
      if (p.isPendingPooledOffer) continue; // not on the map until accepted
      if (p.pickupLatitude != null && p.pickupLongitude != null && !p.isOnboard && !p.isDropped) {
        markers.add(Marker(
          markerId: MarkerId("pickup_${p.id}"),
          position: LatLng(p.pickupLatitude!, p.pickupLongitude!),
          infoWindow: InfoWindow(
            title: "${'Pickup'.tr()} · ${p.passengerName ?? 'Passenger'.tr()}",
          ),
          icon: pickupIcon,
        ));
      }
      if (p.dropoffLatitude != null && p.dropoffLongitude != null && !p.isDropped) {
        markers.add(Marker(
          markerId: MarkerId("dropoff_${p.id}"),
          position: LatLng(p.dropoffLatitude!, p.dropoffLongitude!),
          infoWindow: InfoWindow(
            title: "${'Drop-off'.tr()} · ${p.passengerName ?? 'Passenger'.tr()}",
          ),
          icon: dropoffIcon,
        ));
      }
    }
    mapMarkers = markers;
    await _updateDriverMarker();
  }

  Future<void> _updateDriverMarker() async {
    if (driverLatLng == null) return;
    mapMarkers.removeWhere((m) => m.markerId.value == "driver");
    final icon = await _icon(AppImages.driverCar);
    mapMarkers.add(Marker(
      markerId: const MarkerId("driver"),
      position: driverLatLng!,
      infoWindow: InfoWindow(title: "You".tr()),
      icon: icon,
    ));
  }

  Future<BitmapDescriptor> _icon(String asset) async {
    return await BitmapDescriptor.asset(
      const ImageConfiguration(devicePixelRatio: 1.1, size: Size(28, 28)),
      asset,
    );
  }

  // ---- camera -----------------------------------------------------------
  void _fitCamera() {
    if (_disposed || mapController == null) return;
    final pts = <LatLng>[
      if (driverLatLng != null) driverLatLng!,
      ...orderedStops.map((s) => s.latLng),
    ];
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 14));
      return;
    }
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(_bounds(pts), 70));
  }

  LatLngBounds _bounds(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (final p in list) {
      if (x0 == null) {
        x0 = x1 = p.latitude;
        y0 = y1 = p.longitude;
      } else {
        if (p.latitude > x1!) x1 = p.latitude;
        if (p.latitude < x0) x0 = p.latitude;
        if (p.longitude > y1!) y1 = p.longitude;
        if (p.longitude < y0!) y0 = p.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1 ?? 0, y1 ?? 0),
      southwest: LatLng(x0 ?? 0, y0 ?? 0),
    );
  }

  // ---- external turn-by-turn navigation ---------------------------------
  Future<void> navigateToNextStop() async {
    final s = nextStop;
    if (s != null) await navigateTo(s);
  }

  Future<void> navigateTo(SharedStop s) async {
    final url =
        "https://www.google.com/maps/dir/?api=1&destination=${s.lat},${s.lng}&travelmode=driving";
    try {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      toastError("Could not open navigation".tr());
    }
  }

}
