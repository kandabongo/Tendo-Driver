import 'package:flutter_test/flutter_test.dart';
import 'package:fuodz/constants/api.dart';
import 'package:fuodz/models/shared_trip_offer.dart';

/// SHARED RIDES (driver) — offer parsing + server-driven countdown. Pure and
/// deterministic: it exercises how the app interprets the backend's real
/// `/taxi/shared/offers` payload, not a mocked "success" response.
void main() {
  group('SharedTripOffer parses the backend /offers payload', () {
    final json = {
      'offer_id': 12,
      'shared_trip_id': 34,
      'expires_at': '2026-11-23T10:00:30+00:00',
      'seconds_remaining': 25,
      'seats_taken': 1,
      'max_seats': 4,
      'origin_latitude': -15.3875,
      'origin_longitude': 28.3228,
      'dest_latitude': -15.4167,
      'dest_longitude': 28.2833,
      'passengers': 1,
    };

    test('maps every field', () {
      final o = SharedTripOffer.fromJson(json);
      expect(o.offerId, 12);
      expect(o.sharedTripId, 34);
      expect(o.secondsRemaining, 25);
      expect(o.maxSeats, 4);
      expect(o.originLatitude, closeTo(-15.3875, 1e-6));
      expect(o.passengers, 1);
    });

    test('tolerates string numerics and missing fields', () {
      final o = SharedTripOffer.fromJson({
        'offer_id': '7',
        'shared_trip_id': '8',
        'seconds_remaining': '15',
      });
      expect(o.offerId, 7);
      expect(o.sharedTripId, 8);
      expect(o.secondsRemaining, 15);
      expect(o.maxSeats, isNull);
      expect(o.passengers, 0);
    });
  });

  group('countdown is driven by the server expiry', () {
    test('remainingSeconds prefers expires_at and never goes negative', () {
      final now = DateTime.parse('2026-11-23T10:00:00+00:00');
      final live = SharedTripOffer(
        offerId: 1, sharedTripId: 1,
        expiresAt: DateTime.parse('2026-11-23T10:00:20+00:00'), secondsRemaining: 99,
      );
      expect(live.remainingSeconds(now), 20); // from expires_at, not 99
      expect(live.isExpired(now), isFalse);

      final past = SharedTripOffer(
        offerId: 2, sharedTripId: 2,
        expiresAt: DateTime.parse('2026-11-23T09:59:55+00:00'), secondsRemaining: 10,
      );
      expect(past.remainingSeconds(now), 0);
      expect(past.isExpired(now), isTrue);
    });

    test('falls back to seconds_remaining when no expiry', () {
      final o = SharedTripOffer(offerId: 3, sharedTripId: 3, secondsRemaining: 12);
      expect(o.remainingSeconds(), 12);
    });
  });

  test('offers endpoint matches the backend route', () {
    expect(Api.sharedRideOffers, '/taxi/shared/offers');
  });
}
