import 'package:fuodz/constants/api.dart';
import 'package:fuodz/models/api_response.dart';
import 'package:fuodz/models/driver_subscription.dart';
import 'package:fuodz/models/driver_subscription_state.dart';
import 'package:fuodz/services/http.service.dart';

class SubscriptionRequest extends HttpService {
  Future<DriverSubscriptionState> driverSubscriptionState() async {
    final apiResult = await get(Api.driverSubscriptionState);
    final apiResponse = ApiResponse.fromResponse(apiResult);

    if (apiResponse.allGood) {
      return DriverSubscriptionState.fromJson(apiResponse.body);
    }

    throw "${apiResponse.message}";
  }

  Future<List<DriverSubscription>> driverSubscriptions() async {
    final apiResult = await get(Api.driverSubscriptions);
    final apiResponse = ApiResponse.fromResponse(apiResult);

    if (apiResponse.allGood) {
      return (apiResponse.body as List).map((e) {
        return DriverSubscription.fromJson(e);
      }).toList();
    }

    throw "${apiResponse.message}";
  }

  Future<String?> subscribe(int subscriptionId) async {
    final apiResult = await post(Api.driverSubscriptionSubscribe, {
      "driver_subscription_id": subscriptionId,
    });
    final apiResponse = ApiResponse.fromResponse(apiResult);

    if (apiResponse.allGood) {
      return apiResponse.body["link"] ??
          apiResponse.body["payment_link"] ??
          apiResponse.body["url"];
    }

    throw "${apiResponse.message}";
  }
}
