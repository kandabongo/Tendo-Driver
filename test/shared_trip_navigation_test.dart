import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fuodz/view_models/taxi/shared_trip.vm.dart';

/// SHARED RIDES (driver) — provisional nearest-next stop ordering for the
/// navigation screen. Pure + deterministic. This ordering is a driver aid only;
/// it never changes server-authoritative lifecycle state, which the backend owns.
void main() {
  SharedStop stop(int id, double lat, double lng, {String type = "pickup"}) =>
      SharedStop(passengerId: id, type: type, label: "P$id", lat: lat, lng: lng);

  group('orderStopsNearestFrom', () {
    test('returns input unchanged with no origin', () {
      final stops = [stop(1, -15.40, 28.30), stop(2, -15.38, 28.32)];
      expect(orderStopsNearestFrom(stops, null), same(stops));
    });

    test('returns input unchanged with a single stop', () {
      final stops = [stop(1, -15.40, 28.30)];
      final from = const LatLng(-15.39, 28.31);
      expect(orderStopsNearestFrom(stops, from).map((s) => s.passengerId),
          [1]);
    });

    test('orders multiple stops nearest-first from the driver', () {
      // Driver near passenger 3; farthest is passenger 1.
      final from = const LatLng(-15.380, 28.320);
      final stops = [
        stop(1, -15.500, 28.500), // far
        stop(2, -15.420, 28.360), // mid
        stop(3, -15.381, 28.321), // nearest
      ];
      final ordered =
          orderStopsNearestFrom(stops, from).map((s) => s.passengerId).toList();
      expect(ordered.first, 3);
      expect(ordered.last, 1);
      expect(ordered, [3, 2, 1]);
    });

    test('greedy chaining: nearest-to-cursor, not nearest-to-origin', () {
      // From origin, A is nearest. After A, C is nearer to A than B is.
      final from = const LatLng(0.0, 0.0);
      final a = stop(1, 0.0, 0.10); // closest to origin
      final b = stop(2, 0.0, 0.40); // farthest
      final c = stop(3, 0.0, 0.18); // between, closest to A
      final ordered = orderStopsNearestFrom([b, a, c], from)
          .map((s) => s.passengerId)
          .toList();
      expect(ordered, [1, 3, 2]); // A -> C -> B
    });
  });
}
