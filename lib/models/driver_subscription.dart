class DriverSubscription {
  int id;
  String name;
  String type;
  int? days;
  int? orderLimit;
  double amount;
  bool isActive;

  DriverSubscription({
    required this.id,
    required this.name,
    required this.type,
    required this.days,
    required this.orderLimit,
    required this.amount,
    required this.isActive,
  });

  factory DriverSubscription.fromJson(Map<String, dynamic> json) =>
      DriverSubscription(
        id: json["id"],
        name: json["name"],
        type: json["type"],
        days: int.tryParse(json["days"].toString()),
        orderLimit: int.tryParse(json["order_limit"].toString()),
        amount: double.tryParse(json["amount"].toString()) ?? 0.00,
        isActive:
            (json["is_active"] is bool)
                ? json["is_active"]
                : bool.tryParse(json["is_active"], caseSensitive: false) ??
                    false,
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "type": type,
    "days": days,
    "order_limit": orderLimit,
    "amount": amount,
    "is_active": isActive,
  };
}
