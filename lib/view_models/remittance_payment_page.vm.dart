import 'package:flutter/material.dart';
import 'package:fuodz/extensions/context.dart';
import 'package:fuodz/requests/wallet.request.dart';
import 'package:fuodz/services/alert.service.dart';
import 'package:fuodz/view_models/base.view_model.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

class RemittancePaymentPageViewModel extends MyBaseViewModel {
  RemittancePaymentPageViewModel(BuildContext context, this.amount) {
    this.viewContext = context;
  }

  final double amount;
  final walletRequest = WalletRequest();

  //
  processRemittancePayment() async {
    clearErrors();
    setBusy(true);
    try {
      final apiResponse = await walletRequest.payRemittanceBalance(amount);
      bool isPartialSettlement = apiResponse.body["partial_settlement"] ?? true;
      if (!isPartialSettlement) {
        toastSuccessful("Payment successful".tr());
      } else {
        await AlertService.success(
          title: "Payment successful".tr(),
          text:
              "Due to wallet balance being low, payment was made partially"
                  .tr(),
        );
      }
      viewContext.pop(true);
    } catch (error) {
      setError(error);
      AlertService.error(title: "Payment failed".tr(), text: error.toString());
    }
    setBusy(false);
  }
}
