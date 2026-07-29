import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/constants/sizes.dart';
import 'package:fuodz/view_models/wallet.vm.dart';
import 'package:fuodz/widgets/base.page.dart';
import 'package:fuodz/widgets/busy_indicator.dart';
import 'package:fuodz/widgets/buttons/custom_button.dart';
import 'package:fuodz/widgets/custom_list_view.dart';
import 'package:fuodz/widgets/list_items/wallet_transaction.list_item.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:intl/intl.dart';
import 'package:fuodz/utils/ui_spacer.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with WidgetsBindingObserver {
  WalletViewModel? vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      vm?.getWalletBalance();
    }
  }

  @override
  Widget build(BuildContext context) {
    vm ??= WalletViewModel(context);

    return BasePage(
      title: "Wallet".tr(),
      showLeadingAction: true,
      showAppBar: true,
      body: ViewModelBuilder<WalletViewModel>.reactive(
        viewModelBuilder: () => vm!,
        onViewModelReady: (vm) => vm.initialise(),
        builder: (context, vm, child) {
          return SmartRefresher(
            controller: vm.refreshController,
            enablePullDown: true,
            enablePullUp: true,
            onRefresh: vm.initialise,
            onLoading: () => vm.getWalletTransactions(initialLoading: false),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Sizes.paddingSizeDefault),
              child: VStack([
                // Balance Card
                _buildBalanceCard(context, vm),
                24.heightBox,

                // Top Up Action
                CustomButton(
                  loading: vm.isBusy,
                  title: "Top-Up Wallet".tr(),
                  icon: HugeIcons.strokeRoundedCreditCardAdd,
                  iconColor: Colors.white,
                  color: AppColor.primaryColor,
                  onPressed: vm.showAmountEntry,
                  shapeRadius: 12,
                  elevation: .8,
                ).wFull(context),
                24.heightBox,

                // Transactions Section
                "Recent Transactions".tr().text.xl.bold.make().pOnly(
                  bottom: 12,
                ),

                CustomListView(
                  noScrollPhysics: true,
                  isLoading: vm.busy(vm.walletTransactions),
                  dataSet: vm.walletTransactions,
                  itemBuilder: (context, index) {
                    return WalletTransactionListItem(
                      vm.walletTransactions[index],
                    );
                  },
                  separatorBuilder: (_, __) => UiSpacer.divider().py12(),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, WalletViewModel vm) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColor.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColor.primaryColor,
            AppColor.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background Decor
          Positioned(
            right: -20,
            top: -20,
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedWallet02,
              size: 150,
              color: Colors.white.withOpacity(0.1),
            ),
          ),

          VStack([
            HStack([
              HugeIcon(
                icon: HugeIcons.strokeRoundedWallet02,
                color: Colors.white,
                size: 28,
              ),
              12.widthBox,
              "Total Balance".tr().text.white.lg.medium.make(),
            ]),
            30.heightBox,
            vm.isBusy
                ? BusyIndicator(color: Colors.white).centered()
                : "${AppStrings.currencySymbol} ${vm.wallet?.balance ?? '0.00'}"
                    .text
                    .white
                    .size(36)
                    .bold
                    .make(),
            20.heightBox,
            if (vm.wallet?.updatedAt != null)
              HStack([
                HugeIcon(
                  icon: HugeIcons.strokeRoundedTime03,
                  color: Colors.white70,
                  size: 14,
                ),
                6.widthBox,
                "Updated: ${DateFormat.yMMMMEEEEd(translator.activeLanguageCode).format(vm.wallet!.updatedAt!)}"
                    .text
                    .color(Colors.white70)
                    .sm
                    .make()
                    .expand(),
              ]),
          ]),
        ],
      ),
    );
  }
}
