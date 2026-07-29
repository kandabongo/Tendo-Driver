import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/constants/sizes.dart';
import 'package:fuodz/extensions/dynamic.dart';
import 'package:fuodz/models/driver_subscription.dart';
import 'package:fuodz/view_models/subscribe.vm.dart';
import 'package:fuodz/widgets/base.page.dart';
import 'package:fuodz/widgets/buttons/custom_button.dart';
import 'package:fuodz/widgets/custom_list_view.dart';
import 'package:fuodz/widgets/states/empty.state.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

class SubscribePage extends StatelessWidget {
  const SubscribePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Subscribe".tr(),
      showLeadingAction: true,
      showAppBar: true,
      body: ViewModelBuilder<SubscribeViewModel>.reactive(
        viewModelBuilder: () => SubscribeViewModel(context),
        onViewModelReady: (vm) => vm.initialise(),
        builder: (context, vm, child) {
          return VStack([
            "Choose a subscription".tr().text.xl2.bold.make(),
            6.heightBox,
            "Select a plan that matches how you work".tr().text.gray500.make(),
            16.heightBox,
            _WalletPaymentHint(),
            20.heightBox,
            CustomListView(
              noScrollPhysics: true,
              isLoading: vm.busy(vm.subscriptions),
              dataSet: vm.subscriptions,
              itemBuilder: (context, index) {
                final subscription = vm.subscriptions[index];
                return _SubscriptionPlanItem(
                  subscription: subscription,
                  selected: vm.selectedSubscription?.id == subscription.id,
                  onPressed: () => vm.selectSubscription(subscription),
                );
              },
              emptyWidget: EmptyState(
                title: "No subscriptions available".tr(),
                description:
                    "Available subscription plans will appear here".tr(),
              ),
            ).expand(),
            16.heightBox,
            CustomButton(
              title: "Subscribe".tr(),
              icon: HugeIcons.strokeRoundedCreditCardAccept,
              loading: vm.isBusy,
              onPressed: vm.selectedSubscription == null ? null : vm.subscribe,
              shapeRadius: Sizes.radiusDefault,
            ).wFull(context),
          ]).p(Sizes.paddingSizeDefault);
        },
      ),
    );
  }
}

class _WalletPaymentHint extends StatelessWidget {
  const _WalletPaymentHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Sizes.radiusDefault),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: HStack([
        HugeIcon(
          icon: HugeIcons.strokeRoundedWallet02,
          color: Colors.orange[700],
          size: 20,
        ),
        10.widthBox,
        "Subscription fees will be charged from your wallet. If you do not have enough balance, please go to your wallet and top up your account balance."
            .tr()
            .text
            .sm
            .color(Colors.orange[800])
            .lineHeight(1.4)
            .make()
            .expand(),
      ]),
    );
  }
}

class _SubscriptionPlanItem extends StatelessWidget {
  const _SubscriptionPlanItem({
    required this.subscription,
    required this.selected,
    required this.onPressed,
  });

  final DriverSubscription subscription;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(Sizes.radiusDefault),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(Sizes.radiusDefault),
          border: Border.all(
            color: selected ? AppColor.primaryColor : Colors.black12,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: VStack([
          HStack([
            HugeIcon(
              icon: HugeIcons.strokeRoundedLicense,
              color: selected ? AppColor.primaryColor : Colors.grey,
              size: 28,
            ),
            12.widthBox,
            VStack([
              subscription.name.text.lg.semiBold.make(),
              4.heightBox,
              subscription.type.tr().text.sm.gray500.make(),
            ]).expand(),
            _SelectionIndicator(selected: selected),
          ]),
          16.heightBox,
          "${AppStrings.currencySymbol} ${subscription.amount}"
              .currencyFormat()
              .text
              .xl2
              .bold
              .color(AppColor.primaryColor)
              .make(),
          12.heightBox,
          HStack([
            _PlanMeta(
              icon: HugeIcons.strokeRoundedCalendar03,
              label:
                  subscription.days == null
                      ? "Unlimited days".tr()
                      : "%s days".tr().fill([subscription.days]),
            ).expand(),
            12.widthBox,
            _PlanMeta(
              icon: HugeIcons.strokeRoundedTask01,
              label:
                  subscription.orderLimit == null
                      ? "Unlimited orders".tr()
                      : "%s orders".tr().fill([subscription.orderLimit]),
            ).expand(),
          ]),
          14.heightBox,
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(Sizes.radiusSmall),
            ),
            child: HStack([
              Icon(Icons.info_outline, color: AppColor.primaryColor, size: 18),
              8.widthBox,
              _planHint.text.sm.gray700.make().expand(),
            ]),
          ),
        ]),
      ),
    );
  }

  String get _planHint {
    final type = subscription.type.toLowerCase();
    final daysText =
        subscription.days == null
            ? "unlimited days".tr()
            : "%s days".tr().fill([subscription.days]);
    final orderLimitText =
        subscription.orderLimit == null
            ? "unlimited number of assigned orders".tr()
            : "%s assigned orders".tr().fill([subscription.orderLimit]);

    if (type.contains("time")) {
      return "You will be able to handle unlimited number of assigned orders for %s"
          .tr()
          .fill([daysText]);
    }

    if (type.contains("order")) {
      if (subscription.days == null) {
        return "You will be able to handle %s".tr().fill([orderLimitText]);
      }

      return "You will be able to handle %s within %s".tr().fill([
        orderLimitText,
        daysText,
      ]);
    }

    return "You will be able to handle %s for %s".tr().fill([
      orderLimitText,
      daysText,
    ]);
  }
}

class _PlanMeta extends StatelessWidget {
  const _PlanMeta({required this.icon, required this.label});

  final dynamic icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return HStack([
      HugeIcon(icon: icon, color: Colors.grey, size: 18),
      6.widthBox,
      label.text.sm.gray600.make().expand(),
    ]);
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? AppColor.primaryColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColor.primaryColor : Colors.grey,
          width: 2,
        ),
      ),
      child: selected ? Icon(Icons.check, color: Colors.white, size: 14) : null,
    );
  }
}
