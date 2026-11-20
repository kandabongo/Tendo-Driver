import 'package:flutter/material.dart';
import 'package:fuodz/models/shared_trip.dart';
import 'package:fuodz/view_models/taxi/shared_trip.vm.dart';
import 'package:fuodz/widgets/busy_indicator.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:stacked/stacked.dart';

/// SHARED RIDES (driver) — one trip, many passengers. Shows every passenger's
/// pickup/dropoff and status, and lets the driver start/complete each journey
/// independently. Handles loading / error+retry / empty states.
class SharedTripPage extends StatelessWidget {
  const SharedTripPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SharedTripViewModel>.reactive(
      viewModelBuilder: () => SharedTripViewModel(context),
      onViewModelReady: (model) => model.loadTrip(),
      builder: (context, model, child) {
        return Scaffold(
          appBar: AppBar(title: Text("Shared Trip".tr())),
          body: RefreshIndicator(
            onRefresh: () => model.loadTrip(),
            child: _body(context, model),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, SharedTripViewModel model) {
    if (model.isBusy && !model.hasTrip) {
      return const Center(child: BusyIndicator());
    }
    if (model.lastError != null && !model.hasTrip) {
      return _error(context, model);
    }
    if (!model.hasTrip || model.passengers.isEmpty) {
      return _empty(context, model);
    }

    final trip = model.trip!;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Trip #${trip.id}".tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "${trip.seatsTaken}/${trip.maxSeats} ${'seats'.tr()}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        ...model.passengers
            .map((p) => _passengerCard(context, model, p))
            .toList(),
      ],
    );
  }

  Widget _passengerCard(
      BuildContext context, SharedTripViewModel model, SharedTripPassenger p) {
    final busy = model.isPassengerBusy(p.id);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.person_pin_circle_rounded, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.passengerName ?? "Passenger".tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _statusChip(p.status),
              ],
            ),
            const SizedBox(height: 8),
            _point(Icons.my_location, "Pickup".tr(), p.pickupLatitude,
                p.pickupLongitude),
            _point(Icons.location_on, "Drop-off".tr(), p.dropoffLatitude,
                p.dropoffLongitude),
            const SizedBox(height: 10),
            _actions(context, model, p, busy),
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, SharedTripViewModel model,
      SharedTripPassenger p, bool busy) {
    if (p.isDropped) {
      return const SizedBox.shrink();
    }
    if (p.isOnboard) {
      return ElevatedButton.icon(
        onPressed: busy ? null : () => model.completePassenger(p),
        icon: busy
            ? const SizedBox(
                width: 16, height: 16, child: BusyIndicator())
            : const Icon(Icons.flag_rounded, size: 18),
        label: Text("Complete journey".tr()),
      );
    }
    return OutlinedButton.icon(
      onPressed: busy ? null : () => model.startPassenger(p),
      icon: busy
          ? const SizedBox(width: 16, height: 16, child: BusyIndicator())
          : const Icon(Icons.play_arrow_rounded, size: 18),
      label: Text("Start (passenger onboard)".tr()),
    );
  }

  Widget _point(IconData icon, String label, double? lat, double? lng) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              (lat == null || lng == null)
                  ? "-"
                  : "${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}",
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color c;
    switch (status) {
      case "onboard":
        c = Colors.blue;
        break;
      case "dropped":
        c = Colors.green;
        break;
      case "accepted":
        c = Colors.orange;
        break;
      default:
        c = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.tr(),
          style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    );
  }

  Widget _empty(BuildContext context, SharedTripViewModel model) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.groups_rounded, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        Center(child: Text("No active shared trip".tr())),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => model.loadTrip(),
            icon: const Icon(Icons.refresh),
            label: Text("Refresh".tr()),
          ),
        ),
      ],
    );
  }

  Widget _error(BuildContext context, SharedTripViewModel model) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.redAccent),
        const SizedBox(height: 12),
        Center(child: Text(model.lastError ?? "Something went wrong".tr())),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton.icon(
            onPressed: () => model.retry(),
            icon: const Icon(Icons.refresh),
            label: Text("Retry".tr()),
          ),
        ),
      ],
    );
  }
}
