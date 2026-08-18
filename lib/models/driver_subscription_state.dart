import 'package:fuodz/models/subscription_plan.dart';

class DriverSubscriptionState {
  DriverSubscriptionState({
    required this.hasActiveSubscription,
    this.subscription,
    this.latestSubscription,
  });

  final bool hasActiveSubscription;
  final SubscriptionPlan? subscription;
  final SubscriptionPlan? latestSubscription;

  factory DriverSubscriptionState.fromJson(dynamic json) {
    final body = json is Map && json["data"] is Map ? json["data"] : json;

    if (body is! Map) {
      return DriverSubscriptionState(hasActiveSubscription: false);
    }

    return DriverSubscriptionState(
      hasActiveSubscription: _parseBool(body["has_active_subscription"]),
      subscription: _subscriptionFromJson(
        body["subscription"],
        isActive: _parseBool(body["has_active_subscription"]),
      ),
      latestSubscription: _subscriptionFromJson(body["latest_subscription"]),
    );
  }

  static SubscriptionPlan? _subscriptionFromJson(
    dynamic value, {
    bool isActive = false,
  }) {
    if (value is Map) {
      return SubscriptionPlan.fromJson(
        Map<String, dynamic>.from(value),
        isActive: isActive,
      );
    }

    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    return bool.tryParse("$value", caseSensitive: false) ?? false;
  }
}
