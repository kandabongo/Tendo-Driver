import 'package:fuodz/constants/api.dart';
import 'package:fuodz/models/api_response.dart';
import 'package:fuodz/models/shared_trip.dart';
import 'package:fuodz/models/shared_trip_offer.dart';
import 'package:fuodz/services/http.service.dart';

/// SHARED RIDES (driver) — trip + passenger lifecycle API. Server-authoritative;
/// the backend prevents duplicate acceptance/completion and double earnings.
class SharedTripRequest extends HttpService {
  /// The driver's current active shared trip with its passengers (or null).
  Future<DriverSharedTrip?> currentTrip() async {
    final apiResult = await get(Api.sharedRideCurrentTrip);
    final apiResponse = ApiResponse.fromResponse(apiResult);
    if (apiResponse.allGood && apiResponse.body is Map) {
      final body = Map<String, dynamic>.from(apiResponse.body);
      if (body["trip"] == null) {
        return null;
      }
      return DriverSharedTrip.fromResponse(body);
    }
    throw apiResponse.message ?? "Unable to load shared trip";
  }

  /// Incoming offers for THIS authenticated driver (server returns only their
  /// own pending, un-expired offers). Nearest/eligibility already decided server-side.
  Future<List<SharedTripOffer>> offers() async {
    final apiResult = await get(Api.sharedRideOffers);
    final apiResponse = ApiResponse.fromResponse(apiResult);
    if (apiResponse.allGood && apiResponse.body is Map) {
      final body = Map<String, dynamic>.from(apiResponse.body);
      final list = (body["offers"] as List?) ?? [];
      return list
          .map((e) => SharedTripOffer.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<ApiResponse> acceptTrip(int tripId) async {
    return ApiResponse.fromResponse(
        await post("${Api.sharedRideTrip}/$tripId/accept", {}));
  }

  Future<ApiResponse> declineTrip(int tripId) async {
    return ApiResponse.fromResponse(
        await post("${Api.sharedRideTrip}/$tripId/decline", {}));
  }

  /// Start a passenger's leg (passenger onboard).
  /// Driver is en route to a passenger's pickup (server-authoritative status).
  Future<ApiResponse> enRoutePassenger(int passengerId) async {
    return ApiResponse.fromResponse(
        await post("${Api.sharedRidePassenger}/$passengerId/en_route", {}));
  }

  Future<ApiResponse> startPassenger(int passengerId) async {
    return ApiResponse.fromResponse(
        await post("${Api.sharedRidePassenger}/$passengerId/start", {}));
  }

  /// Complete a passenger's leg (settles their fare/commission server-side).
  Future<ApiResponse> completePassenger(int passengerId) async {
    return ApiResponse.fromResponse(
        await post("${Api.sharedRidePassenger}/$passengerId/complete", {}));
  }
}
