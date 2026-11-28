import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/extensions/context.dart';
import 'package:fuodz/models/shared_trip_offer.dart';
import 'package:fuodz/requests/shared_trip.request.dart';
import 'package:fuodz/services/alert.service.dart';
import 'package:fuodz/services/app.service.dart';
import 'package:fuodz/view_models/base.view_model.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:velocity_x/velocity_x.dart';

/// SHARED RIDES (driver) — incoming-offer controller.
///
/// Server-authoritative: it only renders the backend's offer and relays the
/// driver's accept/decline to the registered endpoints. The backend decides
/// expiry/eligibility/single-winner; this VM never duplicates that logic. The
/// screen pops with the shared_trip_id on a successful accept (caller then opens
/// SharedTripPage), or null on decline / expiry / backend rejection.
class SharedOfferViewModel extends MyBaseViewModel {
  final SharedTripOffer offer;
  final SharedTripRequest request;
  final CountDownController countdownController = CountDownController();
  bool handled = false;

  SharedOfferViewModel(this.offer, BuildContext context, {SharedTripRequest? request})
      : request = request ?? SharedTripRequest() {
    this.viewContext = context;
  }

  /// Countdown length = seconds left per the server's expiry (never negative).
  int get duration => offer.remainingSeconds();

  void initialise() {
    AppService().playNotificationSound();
    if (duration <= 0) {
      onCountdownComplete();
      return;
    }
    countdownController.start();
  }

  Future<void> accept() async {
    if (handled) return;
    handled = true;
    countdownController.pause();
    setBusy(true);
    try {
      final res = await request.acceptTrip(offer.sharedTripId);
      AppService().audioPlayer.stop();
      if (res.allGood) {
        _pop(offer.sharedTripId); // success -> navigate into SharedTripPage
      } else {
        // Backend rejected: expired / already assigned / not eligible. Show the
        // REASON in a persistent dialog (not a fleeting toast) so the driver
        // understands why no trip opened, instead of silently landing on home.
        _pop(null);
        AlertService.error(
          title: "Couldn't accept trip".tr(),
          text: res.message ?? "This shared offer is no longer available.".tr(),
        );
      }
    } catch (e) {
      _pop(null);
      AlertService.error(
        title: "Couldn't accept trip".tr(),
        text: "$e",
      );
    }
    setBusy(false);
  }

  Future<void> decline() async {
    if (handled) return;
    handled = true;
    countdownController.pause();
    setBusy(true);
    try {
      await request.declineTrip(offer.sharedTripId);
    } catch (_) {
      // best-effort: the server re-offers on timeout regardless
    }
    AppService().audioPlayer.stop();
    setBusy(false);
    _pop(null);
  }

  /// Timer elapsed — the server has (or will) expire it; just dismiss.
  void onCountdownComplete() {
    if (handled) return;
    handled = true;
    AppService().audioPlayer.stop();
    _pop(null);
  }

  void _pop(dynamic result) {
    try {
      viewContext.pop(result);
    } catch (_) {}
  }
}
