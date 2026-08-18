import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/constants/sizes.dart';
import 'package:fuodz/extensions/dynamic.dart';
import 'package:fuodz/models/subscription_plan.dart';
import 'package:fuodz/view_models/subscription.vm.dart';
import 'package:fuodz/widgets/base.page.dart';
import 'package:fuodz/widgets/buttons/custom_button.dart';
import 'package:fuodz/widgets/custom_list_view.dart';
import 'package:fuodz/widgets/states/empty.state.dart';
import 'package:fuodz/widgets/states/loading.shimmer.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:jiffy/jiffy.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SubscriptionViewModel>.reactive(
      viewModelBuilder: () => SubscriptionViewModel(context),
      onViewModelReady: (vm) => vm.initialise(),
      builder: (context, vm, child) {
        return BasePage(
          title: "Subscription".tr(),
          showLeadingAction: true,
          showAppBar: true,
          body: _buildBody(context, vm),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SubscriptionViewModel vm) {
    if (vm.isBusy) {
      return Column(
        children: [
          LoadingShimmer().wFull(context).h20(context).cornerRadius(10),
        ],
      ).p20();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(Sizes.paddingSizeDefault),
      child: VStack([
        _buildActiveSubscription(context, vm),
        24.heightBox,
        "Subscription History".tr().text.xl.bold.make(),
        12.heightBox,
        CustomListView(
          noScrollPhysics: true,
          isLoading: vm.busy(vm.subscriptionHistory),
          dataSet: vm.subscriptionHistory,
          itemBuilder: (context, index) {
            return _SubscriptionHistoryItem(
              subscription: vm.subscriptionHistory[index],
            );
          },
          emptyWidget: EmptyState(
            title: "No subscription history".tr(),
            description: "Your previous subscriptions will appear here".tr(),
          ),
        ),
      ]),
    );
  }

  Widget _buildActiveSubscription(
    BuildContext context,
    SubscriptionViewModel vm,
  ) {
    final subscription = vm.activeSubscription;

    if (!vm.hasActiveSubscription) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(Sizes.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: VStack([
          HugeIcon(
            icon: HugeIcons.strokeRoundedLicense,
            color: AppColor.primaryColor,
            size: 40,
          ),
          12.heightBox,
          (vm.hasExpiredSubscription
                  ? "Subscription expired"
                  : "No active subscription")
              .tr()
              .text
              .xl
              .semiBold
              .center
              .make(),
          8.heightBox,
          "Subscribe to keep receiving eligible driver benefits"
              .tr()
              .text
              .gray500
              .center
              .make(),
          16.heightBox,
          CustomButton(
            title: "Subscribe".tr(),
            icon: HugeIcons.strokeRoundedCreditCardAccept,
            onPressed: vm.subscribe,
            shapeRadius: Sizes.radiusDefault,
          ).wFull(context),
        ], crossAlignment: CrossAxisAlignment.center),
      );
    }

    return _ActiveSubscriptionCard(subscription: subscription!);
  }
}

class _ActiveSubscriptionCard extends StatelessWidget {
  const _ActiveSubscriptionCard({required this.subscription});

  final SubscriptionPlan subscription;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.primaryColor,
        borderRadius: BorderRadius.circular(Sizes.radiusDefault),
      ),
      child: VStack([
        HStack([
          HugeIcon(
            icon: HugeIcons.strokeRoundedLicense,
            color: Colors.white,
            size: 28,
          ),
          12.widthBox,
          "Active Subscription".tr().text.white.lg.semiBold.make().expand(),
        ]),
        20.heightBox,
        subscription.name.text.white.xl2.bold.make(),
        if (subscription.expiresAt != null) ...[
          8.heightBox,
          "Valid until %s"
              .tr()
              .fill(["${_formatDate(subscription.expiresAt)}"])
              .text
              .white
              .make(),
        ],
        if (subscription.orderLimit != null) ...[
          8.heightBox,
          "%s of %s orders remaining"
              .tr()
              .fill([
                subscription.remainingOrders ?? 0,
                subscription.orderLimit,
              ])
              .text
              .white
              .make(),
        ],
        if (subscription.completedOrders != null) ...[
          8.heightBox,
          "%s completed orders"
              .tr()
              .fill([subscription.completedOrders])
              .text
              .white
              .make(),
        ],
        if (subscription.amount != null) ...[
          8.heightBox,
          "${AppStrings.currencySymbol} ${subscription.amount}"
              .text
              .white
              .semiBold
              .make(),
        ],
      ]),
    );
  }
}

class _SubscriptionHistoryItem extends StatelessWidget {
  const _SubscriptionHistoryItem({required this.subscription});

  final SubscriptionPlan subscription;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(Sizes.radiusDefault),
        border: Border.all(
          color:
              context.textTheme.bodyLarge?.color?.withOpacity(0.08) ??
              Colors.black12,
        ),
      ),
      child: HStack([
        HugeIcon(
          icon: HugeIcons.strokeRoundedCalendar03,
          color: AppColor.primaryColor,
          size: 24,
        ),
        12.widthBox,
        VStack([
          subscription.name.text.semiBold.make(),
          4.heightBox,
          "From %s"
              .tr()
              .fill([_formatDate(subscription.startedAt)])
              .text
              .sm
              .gray500
              .make(),
          "To %s"
              .tr()
              .fill([_formatDate(subscription.expiresAt)])
              .text
              .sm
              .gray500
              .make(),
        ]).expand(),
        subscription.status.tr().text.sm.semiBold.make(),
      ]),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return "N/A".tr();
  }

  return Jiffy.parseFromDateTime(date).format(pattern: 'dd/MM/yyyy  h:mm a');
}
