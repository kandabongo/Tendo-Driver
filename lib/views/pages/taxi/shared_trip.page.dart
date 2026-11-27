import 'package:flutter/material.dart';
import 'package:fuodz/models/shared_trip.dart';
import 'package:fuodz/view_models/taxi/shared_trip.vm.dart';
import 'package:fuodz/widgets/busy_indicator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:stacked/stacked.dart';

/// SHARED RIDES (driver) — dedicated navigation screen for one trip with many
/// passengers. A live map (driver position + every pickup/drop-off), a
/// provisional nearest-next stop order with one-tap turn-by-turn navigation, and
/// per-passenger cards to progress each journey independently.
///
/// The stop ordering is a driver aid only; every lifecycle transition
/// (start/complete) is sent to the backend, which remains authoritative.
class SharedTripPage extends StatelessWidget {
  const SharedTripPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SharedTripViewModel>.reactive(
      viewModelBuilder: () => SharedTripViewModel(context),
      onViewModelReady: (model) {
        model.initNavigation();
        model.loadTrip();
      },
      builder: (context, model, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Shared Trip".tr()),
            actions: [
              if (model.hasTrip)
                TextButton.icon(
                  onPressed: model.cancelling ? null : () => model.cancelTrip(),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.red, size: 18),
                  label: Text("Cancel".tr(),
                      style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => model.loadTrip(),
            child: _body(context, model),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, SharedTripViewModel model) {
    if ((model.isBusy || model.isResolvingTrip) && !model.hasTrip) {
      return _connecting(context);
    }
    if (model.lastError != null && !model.hasTrip) {
      return _error(context, model);
    }
    if (!model.hasTrip || model.passengers.isEmpty) {
      return _empty(context, model);
    }

    final trip = model.trip!;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _map(context, model),
        if (model.nextStop != null) _nextStopBanner(context, model),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
        ...model.passengers
            .map((p) => _passengerCard(context, model, p))
            .toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---- live map ---------------------------------------------------------
  Widget _map(BuildContext context, SharedTripViewModel model) {
    final target = model.driverLatLng ??
        (model.nextStop?.latLng ?? const LatLng(-15.3875, 28.3228));
    return SizedBox(
      height: 260,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: target, zoom: 13),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: model.mapMarkers,
        onMapCreated: model.setMapController,
        zoomControlsEnabled: false,
      ),
    );
  }

  Widget _nextStopBanner(BuildContext context, SharedTripViewModel model) {
    final s = model.nextStop!;
    final colour = s.isPickup ? Colors.orange : Colors.blue;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colour.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colour.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(s.isPickup ? Icons.my_location : Icons.flag_rounded,
              color: colour),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.isPickup
                      ? "${'Next: pick up'.tr()} ${s.label}"
                      : "${'Next: drop off'.tr()} ${s.label}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (model.orderedStops.length > 1)
                  Text(
                    "${model.orderedStops.length} ${'stops remaining'.tr()}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: model.navigateToNextStop,
            icon: const Icon(Icons.navigation_rounded, size: 18),
            label: Text("Navigate".tr()),
          ),
        ],
      ),
    );
  }

  // ---- passenger cards --------------------------------------------------
  Widget _passengerCard(
      BuildContext context, SharedTripViewModel model, SharedTripPassenger p) {
    final busy = model.isPassengerBusy(p.id);
    final order = model.orderedStops.indexWhere((s) => s.passengerId == p.id);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (order >= 0) ...[
                  CircleAvatar(
                    radius: 11,
                    child: Text("${order + 1}",
                        style: const TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                ] else
                  const Icon(Icons.person_pin_circle_rounded, size: 20),
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
            _point(context, model, p, pickup: true),
            _point(context, model, p, pickup: false),
            const SizedBox(height: 10),
            _actions(context, model, p, busy),
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, SharedTripViewModel model,
      SharedTripPassenger p, bool busy) {
    final spinner = const SizedBox(width: 16, height: 16, child: BusyIndicator());

    // Dropped off — journey done.
    if (p.isDropped) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 6),
          Text("Dropped off".tr(), style: const TextStyle(color: Colors.green)),
        ],
      );
    }

    // Onboard — in transit → Complete.
    if (p.isOnboard) {
      return ElevatedButton.icon(
        onPressed: busy ? null : () => model.completePassenger(p),
        icon: busy ? spinner : const Icon(Icons.flag_rounded, size: 18),
        label: Text("Complete journey".tr()),
      );
    }

    // En route → Arrived (client step) → Start (onboard).
    if (p.isEnRoute) {
      if (!model.isArrived(p.id)) {
        return OutlinedButton.icon(
          onPressed: busy ? null : () => model.markArrived(p),
          icon: const Icon(Icons.pin_drop_rounded, size: 18),
          label: Text("Arrived at pickup".tr()),
        );
      }
      return ElevatedButton.icon(
        onPressed: busy ? null : () => model.startPassenger(p),
        icon: busy ? spinner : const Icon(Icons.play_arrow_rounded, size: 18),
        label: Text("Start journey (passenger onboard)".tr()),
      );
    }

    // Accepted / offered — not yet moving → En route.
    return OutlinedButton.icon(
      onPressed: busy ? null : () => model.enRoutePassenger(p),
      icon: busy ? spinner : const Icon(Icons.navigation_rounded, size: 18),
      label: Text("En route to pickup".tr()),
    );
  }

  /// A pickup/drop-off line with a per-stop navigate action.
  Widget _point(BuildContext context, SharedTripViewModel model,
      SharedTripPassenger p,
      {required bool pickup}) {
    final lat = pickup ? p.pickupLatitude : p.dropoffLatitude;
    final lng = pickup ? p.pickupLongitude : p.dropoffLongitude;
    final icon = pickup ? Icons.my_location : Icons.location_on;
    final label = pickup ? "Pickup".tr() : "Drop-off".tr();
    final hasCoords = lat != null && lng != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              !hasCoords
                  ? "-"
                  : "${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}",
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (hasCoords && !p.isDropped)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.navigation_outlined, size: 18),
              onPressed: () => model.navigateTo(SharedStop(
                passengerId: p.id,
                type: pickup ? "pickup" : "dropoff",
                label: p.passengerName ?? "Passenger",
                lat: lat,
                lng: lng,
              )),
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
      case "en_route":
      case "accepted":
        c = Colors.orange;
        break;
      default:
        c = Colors.grey;
    }
    final label = _statusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label.tr(),
          style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case "onboard":
        return "In transit";
      case "dropped":
        return "Dropped off";
      case "en_route":
        return "En route";
      case "accepted":
      case "offered":
        return "Awaiting pickup";
      default:
        return status;
    }
  }

  Widget _connecting(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Center(child: BusyIndicator()),
        const SizedBox(height: 16),
        Center(child: Text("Opening your shared trip…".tr())),
      ],
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
