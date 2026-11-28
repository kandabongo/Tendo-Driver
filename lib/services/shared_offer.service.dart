import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_taxi_settings.dart';
import 'package:fuodz/models/shared_trip_offer.dart';
import 'package:fuodz/requests/shared_trip.request.dart';
import 'package:fuodz/services/app.service.dart';
import 'package:fuodz/views/pages/taxi/shared_trip.page.dart';
import 'package:fuodz/views/pages/taxi/widgets/shared_ride_offer_alert.dart';

/// SHARED RIDES (driver) — surfaces incoming offers.
///
/// The backend is the single source of truth: a push is only a nudge to
/// re-fetch `GET /taxi/shared/offers`. This presents at most one sheet at a
/// time, deduped by offer id, so duplicate or delayed pushes never stack. It
/// also refreshes on app resume so a missed push is recovered. Entirely
/// feature-flag gated.
class SharedOfferService with WidgetsBindingObserver {
  static final SharedOfferService _instance = SharedOfferService._();
  factory SharedOfferService() => _instance;
  SharedOfferService._();

  final SharedTripRequest _request = SharedTripRequest();
  bool _showing = false;
  bool _observing = false;
  final Set<int> _handledOfferIds = {};

  /// Register the resume listener (idempotent). Call once at startup.
  void start() {
    if (_observing) return;
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh(); // recover any missed push
    }
  }

  /// A push arrived — if it's a shared-trip offer, re-fetch the authoritative list.
  void onPush(Map? data) {
    if (data == null) return;
    if ("${data['type']}" == 'shared_trip_offer') {
      refresh();
    }
  }

  /// Fetch the server's current offers and show the first live, unhandled one.
  Future<void> refresh() async {
    if (!AppTaxiSettings.sharedRidesEnabled) return; // feature-flag gated
    if (_showing) return;

    List<SharedTripOffer> offers;
    try {
      offers = await _request.offers();
    } catch (_) {
      return; // transient; app resume / next push will retry
    }

    SharedTripOffer? next;
    for (final o in offers) {
      if (!o.isExpired() && !_handledOfferIds.contains(o.offerId)) {
        next = o;
        break;
      }
    }
    if (next == null) return;
    await _present(next);
  }

  Future<void> _present(SharedTripOffer offer) async {
    final context = AppService().navigatorKey.currentContext;
    if (context == null) return;

    _showing = true;
    _handledOfferIds.add(offer.offerId); // dedupe duplicate/delayed pushes
    final result = await showModalBottomSheet(
      isDismissible: false,
      enableDrag: false,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SharedRideOfferAlert(offer),
    );
    _showing = false;

    if (result is int) {
      final ctx = AppService().navigatorKey.currentContext;
      if (ctx != null) {
        Navigator.of(ctx).push(
          MaterialPageRoute(builder: (_) => const SharedTripPage()),
        );
      }
    } else {
      // declined / expired -> allow a fresh re-offer of a NEW offer to surface
      refresh();
    }
  }
}
