/// SHARED RIDES (driver) — an incoming dispatch offer, exactly as the backend
/// `GET /taxi/shared/offers` returns it. The server is authoritative for the
/// expiry; the UI only renders a countdown from it. No matching/pricing logic
/// lives here — these are display values computed server-side.
class SharedTripOffer {
  final int offerId;
  final int sharedTripId;
  final DateTime? expiresAt;
  final int secondsRemaining;
  final int? seatsTaken;
  final int? maxSeats;
  final double? originLatitude;
  final double? originLongitude;
  final double? destLatitude;
  final double? destLongitude;
  final int passengers;

  SharedTripOffer({
    required this.offerId,
    required this.sharedTripId,
    this.expiresAt,
    this.secondsRemaining = 0,
    this.seatsTaken,
    this.maxSeats,
    this.originLatitude,
    this.originLongitude,
    this.destLatitude,
    this.destLongitude,
    this.passengers = 0,
  });

  static int _int(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static double? _doubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory SharedTripOffer.fromJson(Map<String, dynamic> json) {
    return SharedTripOffer(
      offerId: _int(json["offer_id"]),
      sharedTripId: _int(json["shared_trip_id"]),
      expiresAt: json["expires_at"] != null
          ? DateTime.tryParse(json["expires_at"].toString())
          : null,
      secondsRemaining: _int(json["seconds_remaining"]),
      seatsTaken: json["seats_taken"] == null ? null : _int(json["seats_taken"]),
      maxSeats: json["max_seats"] == null ? null : _int(json["max_seats"]),
      originLatitude: _doubleOrNull(json["origin_latitude"]),
      originLongitude: _doubleOrNull(json["origin_longitude"]),
      destLatitude: _doubleOrNull(json["dest_latitude"]),
      destLongitude: _doubleOrNull(json["dest_longitude"]),
      passengers: _int(json["passengers"]),
    );
  }

  /// Live seconds left, preferring the authoritative `expires_at` when present
  /// (so a delayed push still shows the correct remaining time), else the
  /// server's `seconds_remaining`. Never negative.
  int remainingSeconds([DateTime? now]) {
    if (expiresAt != null) {
      final diff = expiresAt!.difference(now ?? DateTime.now()).inSeconds;
      return diff > 0 ? diff : 0;
    }
    return secondsRemaining > 0 ? secondsRemaining : 0;
  }

  bool isExpired([DateTime? now]) => remainingSeconds(now) <= 0;
}
