import 'package:fuodz/models/api_response.dart';

/// SHARED RIDES (driver) — the shared-ride endpoints return HTTP 200 even when
/// an action is logically rejected (offer expired, trip already taken, not
/// eligible, invalid state transition), signalling the failure in the body as
/// `{"success": false, "message": "..."}`.
///
/// `ApiResponse.allGood` is derived ONLY from the HTTP status code, so on its
/// own it reported those rejections as success. That made a failed accept look
/// like a success: the app navigated to an empty `/current` and the trip
/// appeared to "disappear" with no reason shown. These helpers honour the body
/// flag as well, and degrade to the old behaviour for any response that has no
/// `success` field.
extension SharedApiResponseX on ApiResponse {
  bool get sharedSuccess =>
      allGood && !(body is Map && (body as Map)['success'] == false);

  String? get sharedMessage =>
      (body is Map ? (body as Map)['message'] as String? : null) ?? message;
}
