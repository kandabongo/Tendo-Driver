import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/models/shared_trip_offer.dart';
import 'package:fuodz/view_models/taxi/shared_offer.vm.dart';
import 'package:fuodz/widgets/busy_indicator.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:stacked/stacked.dart';

/// SHARED RIDES (driver) — incoming offer sheet. Mirrors the Taxi
/// IncomingNewOrderAlert pattern (modal, circular countdown, accept/decline) for
/// a pooled trip. All values are server-provided; the countdown is driven by the
/// backend's expiry. Pops with the shared_trip_id on accept, null otherwise.
class SharedRideOfferAlert extends StatefulWidget {
  const SharedRideOfferAlert(this.offer, {Key? key}) : super(key: key);
  final SharedTripOffer offer;

  @override
  State<SharedRideOfferAlert> createState() => _SharedRideOfferAlertState();
}

class _SharedRideOfferAlertState extends State<SharedRideOfferAlert> {
  late SharedOfferViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = SharedOfferViewModel(widget.offer, context);
    WidgetsBinding.instance.addPostFrameCallback((_) => vm.initialise());
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    return ViewModelBuilder<SharedOfferViewModel>.reactive(
      viewModelBuilder: () => vm,
      builder: (context, vm, child) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // header + countdown
                Container(
                  color: AppColor.primaryColor,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "New Shared Trip".tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      CircularCountDownTimer(
                        duration: vm.duration <= 0 ? 1 : vm.duration,
                        controller: vm.countdownController,
                        width: 34,
                        height: 34,
                        ringColor: Colors.white24,
                        fillColor: AppColor.accentColor,
                        backgroundColor: AppColor.primaryColorDark,
                        strokeWidth: 4.0,
                        strokeCap: StrokeCap.round,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textFormat: CountdownTextFormat.S,
                        isReverse: true,
                        isReverseAnimation: false,
                        isTimerTextShown: true,
                        autoStart: false,
                        onComplete: () => vm.onCountdownComplete(),
                      ),
                    ],
                  ),
                ),
                // details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _row(Icons.my_location, "Pickup".tr(),
                          _coord(offer.originLatitude, offer.originLongitude)),
                      const SizedBox(height: 10),
                      _row(Icons.location_on, "Drop-off".tr(),
                          _coord(offer.destLatitude, offer.destLongitude)),
                      const SizedBox(height: 10),
                      _row(
                        Icons.people,
                        "Passengers".tr(),
                        "${offer.passengers} • ${offer.seatsTaken ?? '-'}/${offer.maxSeats ?? '-'} ${'seats'.tr()}",
                      ),
                    ],
                  ),
                ),
                // actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: vm.isBusy
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: BusyIndicator()),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => vm.decline(),
                                child: Text("Decline".tr()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => vm.accept(),
                                child: Text("Accept".tr()),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(color: Colors.grey)),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  String _coord(double? lat, double? lng) {
    if (lat == null || lng == null) return "-";
    return "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
  }
}
