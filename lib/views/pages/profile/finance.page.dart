import 'package:flutter/material.dart';
import 'package:fuodz/constants/sizes.dart';
import 'package:fuodz/view_models/profile.vm.dart';
import 'package:fuodz/widgets/base.page.dart';
import 'package:fuodz/widgets/menu_item.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePage(
      showAppBar: true,
      showLeadingAction: true,
      title: "Finance".tr(),
      body: ViewModelBuilder<ProfileViewModel>.reactive(
        viewModelBuilder: () => ProfileViewModel(context),
        onViewModelReady: (vm) => vm.initialise(),
        builder: (context, model, child) {
          return VStack([
            //Earning
            MenuItem(
              prefix: HugeIcon(icon: HugeIcons.strokeRoundedPieChart03),
              title: "Earning".tr(),
              onPressed: model.showEarning,
              divider: true,
            ),
            //
            MenuItem(
              prefix: HugeIcon(icon: HugeIcons.strokeRoundedWallet01),
              title: "Wallet".tr(),
              onPressed: model.openWallet,
            ),
            //
            //
            MenuItem(
              prefix: HugeIcon(icon: HugeIcons.strokeRoundedBank),
              title: "Payment Accounts".tr(),
              onPressed: model.openPaymentAccounts,
            ),
          ], spacing: Sizes.paddingSizeSmall).p20().scrollVertical();
        },
      ),
    );
  }
}
