import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/constants/app_routes.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/constants/sizes.dart';
import 'package:fuodz/extensions/dynamic.dart';
import 'package:fuodz/requests/report.request.dart';
import 'package:fuodz/widgets/busy_indicator.dart';
import 'package:fuodz/widgets/buttons/custom_button.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

class DriverGeneralStatsView extends StatelessWidget {
  const DriverGeneralStatsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: VStack([
        "Stats".tr().text.xl3.bold.make().px(Sizes.paddingSizeDefault),
        ViewModelBuilder<DriverGeneralStatsViewModel>.reactive(
          viewModelBuilder: () => DriverGeneralStatsViewModel(),
          onViewModelReady: (vm) => vm.fetchDriverStats(),
          builder: (context, vm, child) {
            return vm.isBusy
                ? BusyIndicator().wh(40, 40).centered()
                : SingleChildScrollView(
                  padding: EdgeInsets.all(Sizes.paddingSizeDefault),
                  child: VStack([
                    // Earnings Section with Gradient Card
                    VStack([
                      "Earnings".tr().text.lg.semiBold.make().pOnly(bottom: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            Sizes.radiusDefault,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              AppColor.primaryColor,
                              AppColor.primaryColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColor.primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child:
                            VStack([
                              // Main Balance
                              HStack([
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: HugeIcon(icon: HugeIcons.strokeRoundedWallet01,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                                12.widthBox,
                                VStack([
                                  "Total Balance"
                                      .tr()
                                      .text
                                      .white
                                      .medium
                                      .sm
                                      .make(),
                                  "${AppStrings.currencySymbol} ${vm.earningBalance}"
                                      .currencyFormat()
                                      .text
                                      .white
                                      .xl3
                                      .bold
                                      .make(),
                                ]),
                              ]),

                              20.heightBox,
                              Divider(color: Colors.white.withOpacity(0.2)),
                              10.heightBox,

                              // Stats Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildEarningStat(
                                    "Today",
                                    vm.todayEarningBalance,
                                    isWhite: true,
                                  ),
                                  _buildVerticalDivider(isWhite: true),
                                  _buildEarningStat(
                                    "This Week",
                                    vm.weekEarningBalance,
                                    isWhite: true,
                                  ),
                                  _buildVerticalDivider(isWhite: true),
                                  _buildEarningStat(
                                    "This Month",
                                    vm.monthEarningBalance,
                                    isWhite: true,
                                  ),
                                ],
                              ),
                            ]).p20(),
                      ),
                    ]),

                    // Remittance Section
                    if (vm.pendingRemittance > 0)
                      VStack([
                        "Pending Remittance".tr().text.lg.semiBold.make().pOnly(
                          top: 20,
                          bottom: 8,
                        ),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white, // context.cardColor
                            borderRadius: BorderRadius.circular(
                              Sizes.radiusDefault,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.red.withOpacity(0.1),
                            ),
                          ),
                          child: VStack([
                            HStack([
                              HugeIcon(icon: HugeIcons.strokeRoundedAlert02,
                                color: Colors.red,
                              ),
                              12.widthBox,
                              VStack([
                                "Outstanding Amount"
                                    .tr()
                                    .text
                                    .gray500
                                    .sm
                                    .make(),
                                "${AppStrings.currencySymbol} ${vm.pendingRemittance}"
                                    .currencyFormat()
                                    .text
                                    .xl2
                                    .bold
                                    .red500
                                    .make(),
                              ]).expand(),
                            ]),
                            16.heightBox,
                            CustomButton(
                              onPressed:
                                  () => vm.openRemittancePaymentPage(context),
                              title: "Pay Now".tr(),
                              color: Colors.red,
                            ).wFull(context),
                            8.heightBox,
                            "Note: Payment amount is withdrawn from your wallet balance."
                                .tr()
                                .text
                                .xs
                                .gray400
                                .make(),
                          ]),
                        ),
                      ]),

                    // Order Stats Grid
                    VStack([
                      "Order Statistics".tr().text.lg.semiBold.make().pOnly(
                        top: 20,
                        bottom: 8,
                      ),
                      GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard(
                            title: "Today",
                            value: "${vm.todayOrders}",
                            icon: HugeIcons.strokeRoundedCalendar03,
                            color: Colors.blue,
                          ),
                          _buildStatCard(
                            title: "This Week",
                            value: "${vm.weekOrders}",
                            icon:
                                HugeIcons
                                    .strokeRoundedCalendar03, // Or another icon
                            color: Colors.orange,
                          ),
                          _buildStatCard(
                            title: "This Month",
                            value: "${vm.monthOrders}",
                            icon: HugeIcons.strokeRoundedCalendar01,
                            color: Colors.purple,
                          ),
                          _buildStatCard(
                            title: "All Time",
                            value: "${vm.allTimeOrders}",
                            icon: HugeIcons.strokeRoundedTaskDaily01,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ]),
                  ], spacing: 0),
                );
          },
        ).expand(),
      ]),
    );
  }

  Widget _buildEarningStat(
    String title,
    double amount, {
    bool isWhite = false,
  }) {
    return VStack([
      title
          .tr()
          .text
          .size(10)
          .color(isWhite ? Colors.white70 : Colors.grey)
          .make(),
      "${AppStrings.currencySymbol} $amount"
          .currencyFormat()
          .text
          .sm
          .semiBold
          .color(isWhite ? Colors.white : Colors.black)
          .make(),
    ], crossAlignment: CrossAxisAlignment.center);
  }

  Widget _buildVerticalDivider({bool isWhite = false}) {
    return Container(
      width: 1,
      height: 24,
      color: isWhite ? Colors.white24 : Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required dynamic icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // context.cardColor
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              HugeIcon(icon: icon, size: 18, color: color),
              8.widthBox,
              title.tr().text.sm.gray500.make(),
            ],
          ),
          8.heightBox,
          value.text.xl2.bold.color(Colors.black87).make(),
          "Orders".tr().text.xs.gray400.make(),
        ],
      ),
    );
  }
}

//viewmodel
class DriverGeneralStatsViewModel extends BaseViewModel {
  int todayOrders = 0;
  int weekOrders = 0;
  int monthOrders = 0;
  int allTimeOrders = 0;
  double pendingRemittance = 0.0;
  double earningBalance = 0.0;
  double todayEarningBalance = 0.0;
  double weekEarningBalance = 0.0;
  double monthEarningBalance = 0.0;
  //
  bool showBrief = true;
  //
  fetchDriverStats() async {
    setBusy(true);
    try {
      final metries = await ReportRequest().driverMetrics();
      todayOrders = metries["orders"]["today"] as int;
      weekOrders = metries["orders"]["week"] as int;
      monthOrders = metries["orders"]["month"] as int;
      allTimeOrders = metries["orders"]["all_time"] as int;
      pendingRemittance =
          metries["money"]["pending_remittance"].toString().toDouble();
      earningBalance = metries["earnings"]["current"].toString().toDouble();
      todayEarningBalance = metries["earnings"]["today"].toString().toDouble();
      weekEarningBalance = metries["earnings"]["week"].toString().toDouble();
      monthEarningBalance = metries["earnings"]["month"].toString().toDouble();
      //
    } catch (error) {
      print("Driver stats error: $error");
    }
    setBusy(false);
  }

  toggleStatsView() {
    showBrief = !showBrief;
    notifyListeners();
  }

  openRemittancePaymentPage(BuildContext context) async {
    final result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.remittancePaymentRoute, arguments: pendingRemittance);

    if (result != null && result is bool && result) {
      fetchDriverStats();
    }
  }
}
