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
  });
}
