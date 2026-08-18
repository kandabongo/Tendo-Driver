import 'package:flutter/material.dart';
import 'package:fuodz/extensions/context.dart';
import 'package:fuodz/models/driver_subscription.dart';
import 'package:fuodz/requests/subscription.request.dart';
import 'package:fuodz/services/alert.service.dart';
import 'package:fuodz/view_models/base.view_model.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

class SubscribeViewModel extends MyBaseViewModel {
  SubscribeViewModel(BuildContext context) {
    viewContext = context;
  }

  final subscriptionRequest = SubscriptionRequest();
  List<DriverSubscription> subscriptions = [];
  DriverSubscription? selectedSubscription;

  @override
  void initialise() {
    getSubscriptions();
  }

  void getSubscriptions() async {
    setBusyForObject(subscriptions, true);

    try {
      subscriptions = await subscriptionRequest.driverSubscriptions();
      if (subscriptions.isNotEmpty) {
        selectedSubscription = subscriptions.firstWhere(
          (subscription) => subscription.isActive,
          orElse: () => subscriptions.first,
        );
      }
      clearErrors();
    } catch (error) {
      print(error);
      setErrorForObject(subscriptions, error);
    }

    setBusyForObject(subscriptions, false);
  }

  void selectSubscription(DriverSubscription subscription) {
    selectedSubscription = subscription;
    notifyListeners();
  }

  void subscribe() async {
    final subscription = selectedSubscription;
    if (subscription == null) {
      toastError("Please select a subscription".tr());
      return;
    }

    setBusy(true);
    try {
      final link = await subscriptionRequest.subscribe(subscription.id);
      clearErrors();

      if (link != null && link.isNotEmpty) {
        await openWebpageLink(link);
        viewContext.pop(true);
      } else {
        toastSuccessful("Subscription successful".tr());
        setBusy(false);
        viewContext.pop(true);
        return;
      }
    } catch (error) {
      setError(error);
      AlertService.error(
        title: "Subscription failed".tr(),
        text: error.toString(),
      );
    }
    setBusy(false);
  }
}
