import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/extensions/dynamic.dart';
import 'package:fuodz/view_models/remittance_payment_page.vm.dart';
import 'package:fuodz/widgets/base.page.dart';
import 'package:fuodz/widgets/buttons/custom_button.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

class RemittancePaymentPage extends StatelessWidget {
  const RemittancePaymentPage(this.amount, {Key? key}) : super(key: key);
  final double amount;
  @override
  Widget build(BuildContext context) {
    return BasePage(
      showAppBar: true,
      title: "Remittance Payment".tr(),
      showLeadingAction: true,
      body: ViewModelBuilder<RemittancePaymentPageViewModel>.reactive(
        viewModelBuilder: () => RemittancePaymentPageViewModel(context, amount),
        onViewModelReady: (vm) => vm.initialise(),
        builder: (context, vm, child) {
          return VStack([
            24.heightBox,

            // Payment Info Card
            Container(
              padding: EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: VStack([
                // Illustration
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColor.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedMoneySend02,
                    size: 40,
                    color: AppColor.primaryColor,
                  ),
                ).centered(),

                24.heightBox,

                "Total Amount to Remit".tr().text.gray500.makeCentered(),
                8.heightBox,
                "${AppStrings.currencySymbol} ${amount}"
                    .currencyFormat()
                    .text
                    .size(32)
                    .bold
                    .color(AppColor.primaryColor)
                    .makeCentered(),

                24.heightBox,
                Divider(color: Colors.grey.withOpacity(0.2)),
                24.heightBox,

                "Description".tr().text.sm.semiBold.gray700.make(),
                8.heightBox,
                "This amount represents the cash collected from customers for your orders. To ensure seamless service and avoid account restrictions, please clear this outstanding balance."
                    .tr()
                    .text
                    .sm
                    .gray500
                    .lineHeight(1.5)
                    .make(),
              ]),
            ),

            Spacer(),

            // Note about wallet deduction
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: HStack([
                HugeIcon(icon: HugeIcons.strokeRoundedWallet02,
                  size: 20,
                  color: Colors.orange[700],
                ),
                12.widthBox,
                "Payment will be deducted from your wallet balance. Please ensure you have sufficient funds."
                    .tr()
                    .text
                    .sm
                    .color(Colors.orange[800])
                    .make()
                    .expand(),
              ]),
            ),
            16.heightBox,

            // Action Button
            CustomButton(
              title: "Pay Now".tr(),
              icon: HugeIcons.strokeRoundedCreditCardAccept,
              onPressed: vm.processRemittancePayment,
              loading: vm.isBusy,
              shapeRadius: 12,
              elevation: 2,
            ).wFull(context).h(56),

            24.heightBox,
          ]).p20();
        },
      ),
    );
  }
}
