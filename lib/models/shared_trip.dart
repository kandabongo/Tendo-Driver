/// SHARED RIDES (driver) — a passenger on the driver's shared trip, with their
/// own pickup/dropoff, status and fare. Null-safe parsing throughout.
class SharedTripPassenger {
  final int id;
  final int? orderId;
  final String status;
  final int seatCount;
  final String? passengerName;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final double passengerFare;

  SharedTripPassenger({
    required this.id,
    this.orderId,
    this.status = "offered",
    this.seatCount = 1,
    this.passengerName,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.passengerFare = 0,
  });

  static int _i(dynamic v, [int d = 0]) =>
      v is num ? v.toInt() : (int.tryParse("$v") ?? d);
  static double? _dn(dynamic v) =>
      v == null ? null : (v is num ? v.toDouble() : double.tryParse("$v"));

  factory SharedTripPassenger.fromJson(Map<String, dynamic> json) {
    return SharedTripPassenger(
      id: _i(json["id"]),
      orderId: json["order_id"] == null ? null : _i(json["order_id"]),
      status: (json["status"] ?? "offered").toString(),
      seatCount: _i(json["seat_count"], 1),
      passengerName: json["passenger_name"]?.toString(),
      pickupLatitude: _dn(json["pickup_latitude"]),
      pickupLongitude: _dn(json["pickup_longitude"]),
      dropoffLatitude: _dn(json["dropoff_latitude"]),
      dropoffLongitude: _dn(json["dropoff_longitude"]),
      passengerFare: _dn(json["passenger_fare"]) ?? 0,
    );
  }

  bool get isOnboard => status == "onboard";
  bool get isDropped => status == "dropped";
  bool get isActive => status != "dropped" && status != "cancelled" && status != "rejected";
}

class DriverSharedTrip {
  final int id;
  final String status;
  final int maxSeats;
  final int seatsTaken;
  final List<SharedTripPassenger> passengers;

  DriverSharedTrip({
    required this.id,
    this.status = "pending",
    this.maxSeats = 0,
    this.seatsTaken = 0,
    this.passengers = const [],
  });

  factory DriverSharedTrip.fromResponse(Map<String, dynamic> json) {
    final trip = (json["trip"] is Map)
        ? Map<String, dynamic>.from(json["trip"])
        : <String, dynamic>{};
    final list = (json["passengers"] is List)
        ? (json["passengers"] as List)
            .whereType<Map>()
            .map((e) => SharedTripPassenger.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <SharedTripPassenger>[];
    return DriverSharedTrip(
      id: SharedTripPassenger._i(trip["id"]),
      status: (trip["status"] ?? "pending").toString(),
      maxSeats: SharedTripPassenger._i(trip["max_seats"]),
      seatsTaken: SharedTripPassenger._i(trip["seats_taken"]),
      passengers: list,
    );
  }

  List<SharedTripPassenger> get activePassengers =>
      passengers.where((p) => p.isActive).toList();
}
