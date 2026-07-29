class SubscriptionPlan {
  SubscriptionPlan({
    this.id,
    required this.name,
    required this.status,
    this.startedAt,
    this.expiresAt,
    this.amount,
    this.type,
    this.orderLimit,
    this.remainingOrders,
    this.completedOrders,
    this.isActive = false,
  });

  final int? id;
  final String name;
  final String status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final String? amount;
  final String? type;
  final int? orderLimit;
  final int? remainingOrders;
  final int? completedOrders;
  final bool isActive;

  factory SubscriptionPlan.fromJson(
    Map<String, dynamic> json, {
    bool isActive = false,
  }) {
    final plan = _planFromJson(json);

    return SubscriptionPlan(
      id: _intFromJson(json["id"]),
      name: "${json["name"] ?? plan["name"] ?? "Subscription"}",
      status: "${json["status"] ?? _statusFromJson(json)}",
      startedAt: _dateFromJson(json, [
        "starts_at",
        "started_at",
        "start_date",
        "subscribed_at",
        "created_at",
      ]),
      expiresAt: _dateFromJson(json, [
        "expires_at",
        "expired_at",
        "ends_at",
        "end_date",
        "expiry_date",
      ]),
      amount: _amountFromJson(json, plan),
      type: "${json["type"] ?? plan["type"] ?? ""}",
      orderLimit: _intFromJson(json["order_limit"] ?? plan["order_limit"]),
      remainingOrders: _intFromJson(json["remaining_orders"]),
      completedOrders: _intFromJson(json["completed_orders"]),
      isActive: isActive,
    );
  }

  static Map<String, dynamic> _planFromJson(Map<String, dynamic> json) {
    final plan =
        json["driver_subscription"] ?? json["subscription"] ?? json["plan"];
    if (plan is Map) {
      return Map<String, dynamic>.from(plan);
    }

    return {};
  }

  static String _statusFromJson(Map<String, dynamic> json) {
    final isActive = bool.tryParse(
      "${json["is_active"] ?? json["active"]}",
      caseSensitive: false,
    );
    if (isActive == true) {
      return "active";
    }

    return "expired";
  }

  static DateTime? _dateFromJson(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }

      final date = DateTime.tryParse("$value");
      if (date != null) {
        return date;
      }
    }

    return null;
  }

  static String? _amountFromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> plan,
  ) {
    final amount = json["amount"] ?? plan["amount"];
    if (amount == null) {
      return null;
    }

    return "$amount";
  }

  static int? _intFromJson(dynamic value) {
    if (value == null) {
      return null;
    }

    return int.tryParse("$value");
  }
}
