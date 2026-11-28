import 'package:flutter_test/flutter_test.dart';
import 'package:fuodz/models/shared_trip.dart';

/// SHARED RIDES (driver) — model/contract tests. Assert the driver models parse
/// the ACTUAL `GET taxi/shared/trip/current` response, and that missing/null
/// values never throw.
void main() {
  group('DriverSharedTrip', () {
    final response = {
      "success": true,
      "trip": {"id": 7, "status": "active", "max_seats": 4, "seats_taken": 2},
      "passengers": [
        {
          "id": 11,
          "order_id": 101,
          "status": "accepted",
          "seat_count": 1,
          "passenger_name": "Alice",
          "pickup_latitude": -15.4,
          "pickup_longitude": 28.3,
          "dropoff_latitude": -15.5,
          "dropoff_longitude": 28.4,
          "passenger_fare": 36,
        },
        {
          "id": 12,
          "order_id": 102,
          "status": "onboard",
          "passenger_name": "Bob",
          "passenger_fare": "23.20",
        },
      ],
    };

    test('parses trip + passengers', () {
      final trip = DriverSharedTrip.fromResponse(Map<String, dynamic>.from(response));
      expect(trip.id, 7);
      expect(trip.status, "active");
      expect(trip.maxSeats, 4);
      expect(trip.seatsTaken, 2);
      expect(trip.passengers.length, 2);

      final a = trip.passengers[0];
      expect(a.id, 11);
      expect(a.passengerName, "Alice");
      expect(a.pickupLatitude, -15.4);
      expect(a.dropoffLongitude, 28.4);
      expect(a.passengerFare, 36);
      expect(a.status, "accepted");
      expect(a.isOnboard, false);

      final b = trip.passengers[1];
      expect(b.isOnboard, true);
      expect(b.passengerFare, 23.2); // string coerced
      expect(b.pickupLatitude, isNull); // missing -> null, no throw
    });

    test('active passengers exclude dropped/cancelled', () {
      final r = {
        "trip": {"id": 1, "status": "active", "max_seats": 4, "seats_taken": 1},
        "passengers": [
          {"id": 1, "status": "onboard"},
          {"id": 2, "status": "dropped"},
          {"id": 3, "status": "cancelled"},
        ],
      };
      final trip = DriverSharedTrip.fromResponse(Map<String, dynamic>.from(r));
      expect(trip.passengers.length, 3);
      expect(trip.activePassengers.map((p) => p.id).toList(), [1]);
    });

    test('empty / malformed payload never throws', () {
      final t1 = DriverSharedTrip.fromResponse({});
      expect(t1.passengers, isEmpty);
      final t2 = DriverSharedTrip.fromResponse({"trip": null, "passengers": "oops"});
      expect(t2.passengers, isEmpty);
      expect(t2.id, 0);
    });

    test('pending pooled offer is flagged and kept off the stop list', () {
      final r = {
        "trip": {"id": 1, "status": "active", "max_seats": 4, "seats_taken": 2},
        "passengers": [
          {"id": 1, "status": "onboard", "passenger_name": "A"},
          {
            "id": 2,
            "status": "offered",
            "is_pending_offer": true,
            "offer_seconds_remaining": 25,
            "passenger_name": "B",
          },
        ],
      };
      final trip = DriverSharedTrip.fromResponse(Map<String, dynamic>.from(r));
      final b = trip.passengers.firstWhere((p) => p.id == 2);
      expect(b.isPendingOffer, isTrue);
      expect(b.isPendingPooledOffer, isTrue);
      expect(b.offerSecondsRemaining, 25);
      // A pending offer is not yet "awaiting pickup" (not a stop to serve).
      expect(b.isAwaitingEnRoute, isFalse);
      // Both still count as active (seat held provisionally).
      expect(trip.activePassengers.length, 2);
    });

    test("a plain 'offered' first passenger (no flag) is awaiting pickup, not a pooled offer", () {
      final r = {
        "trip": {"id": 1, "status": "matching", "max_seats": 4, "seats_taken": 1},
        "passengers": [
          {"id": 1, "status": "offered"}, // no is_pending_offer
        ],
      };
      final trip = DriverSharedTrip.fromResponse(Map<String, dynamic>.from(r));
      final p = trip.passengers.first;
      expect(p.isPendingPooledOffer, isFalse);
      expect(p.isAwaitingEnRoute, isTrue);
    });
  });
}
