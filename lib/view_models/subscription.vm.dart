import 'package:flutter/material.dart';
import 'package:fuodz/extensions/context.dart';
import 'package:fuodz/models/subscription_plan.dart';
import 'package:fuodz/requests/subscription.request.dart';
import 'package:fuodz/view_models/base.view_model.dart';
import 'package:fuodz/views/pages/subscription/subscribe.page.dart';

class SubscriptionViewModel extends MyBaseViewModel {
  SubscriptionViewModel(BuildContext context) {
    viewContext = context;
  }

  SubscriptionPlan? activeSubscription;
  List<SubscriptionPlan> subscriptionHistory = [];
  final subscriptionRequest = SubscriptionRequest();

  bool get hasActiveSubscription {
    final subscription = activeSubscription;
    if (subscription == null) {
      return false;
    }

    if (subscription.isActive) {
      return true;
    }

    return subscription.expiresAt?.isAfter(DateTime.now()) ?? false;
  }

  bool get hasExpiredSubscription {
    final subscription = activeSubscription;
    if (subscription == null) {
      return false;
    }

    return subscription.expiresAt?.isBefore(DateTime.now()) ?? false;
  }

  @override
  void initialise() {
    getSubscription();
  }

  void getSubscription() async {
    setBusy(true);
    setBusyForObject(subscriptionHistory, true);

    try {
      final subscriptionState =
          await subscriptionRequest.driverSubscriptionState();
      activeSubscription = subscriptionState.subscription;
      subscriptionHistory =
          subscriptionState.latestSubscription == null
              ? []
              : [subscriptionState.latestSubscription!];
      clearErrors();
    } catch (error) {
      print("Driver subscription state error ==> $error");
      setError(error);
      setErrorForObject(subscriptionHistory, error);
    }

    setBusyForObject(subscriptionHistory, false);
    setBusy(false);
  }

  void subscribe() async {
    final result = await viewContext.push((context) => SubscribePage());

    if (result == true) {
      getSubscription();
    }
  }
}
