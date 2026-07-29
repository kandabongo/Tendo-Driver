import 'dart:io';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_upgrade_settings.dart';
import 'package:fuodz/services/auth.service.dart';
import 'package:fuodz/utils/color_utils.dart';
import 'package:fuodz/views/pages/finance/finance_report.page.dart';
import 'package:fuodz/views/pages/order/assigned_orders.page.dart';
import 'package:fuodz/view_models/home.vm.dart';
import 'package:fuodz/views/pages/order/orders.page.dart';
import 'package:fuodz/views/pages/profile/profile.page.dart';
import 'package:fuodz/views/pages/taxi/taxi_order.page.dart';
import 'package:fuodz/widgets/base.page.dart';
import 'package:fuodz/widgets/cards/driver_general_stats.view.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:stacked/stacked.dart';
import 'package:upgrader/upgrader.dart';
import 'package:velocity_x/velocity_x.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  //
  @override
  Widget build(BuildContext context) {
    //
    bool isTaxiDriver = AuthServices.currentUser!.isTaxiDriver;
    //
    return DoubleBack(
      message: "Press back again to close".tr(),
      child: ViewModelBuilder<HomeViewModel>.reactive(
        viewModelBuilder: () => HomeViewModel(context),
        onViewModelReady: (model) => model.initialise(),
        builder: (context, model, child) {
          return BasePage(
            body: UpgradeAlert(
              showIgnore: !AppUpgradeSettings.forceUpgrade(),
              shouldPopScope: () => !AppUpgradeSettings.forceUpgrade(),
              dialogStyle:
                  Platform.isIOS
                      ? UpgradeDialogStyle.cupertino
                      : UpgradeDialogStyle.material,
              child: PageView(
                controller: model.pageViewController,
                onPageChanged: model.onPageChanged,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  //
                  if (AuthServices.currentUser!.isTaxiDriver)
                    //taxi driver view
                    TaxiOrderPage(),
                  if (!AuthServices.currentUser!.isTaxiDriver)
                    //regular driver view
                    AssignedOrdersPage(),

                  //
                  OrdersPage(),

                  //finance report stats
                  DriverGeneralStatsView(),

                  //show report page
                  FinanceReportPage(),
                  //
                  ProfilePage(),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: context.theme.canvasColor,
                boxShadow: [
                  BoxShadow(
                    color: context.theme.shadowColor.withOpacity(0.1),
                    blurRadius: 10,
                    //offset for the top only
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: BottomNavigationBar(
                  elevation: 0,
                  selectedItemColor: context.primaryColor,
                  unselectedItemColor: ColorUtils.shuffleColorByMode(
                    context,
                    lightMode: Colors.black,
                    darkMode: Colors.grey.shade500,
                  ),
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  currentIndex: model.currentIndex,
                  onTap: model.onTabChange,
                  items: [
                    BottomNavigationBarItem(
                      icon: HugeIcon(icon: HugeIcons.strokeRoundedHome02),
                      activeIcon: HugeIcon(icon: HugeIcons.strokeRoundedHome03),
                      label: 'Home'.tr(),
                    ),
                    BottomNavigationBarItem(
                      icon: HugeIcon(
                        icon:
                            isTaxiDriver
                                ? HugeIcons.strokeRoundedPinLocation01
                                : HugeIcons.strokeRoundedInboxUnread,
                      ),
                      activeIcon: HugeIcon(
                        icon:
                            isTaxiDriver
                                ? HugeIcons.strokeRoundedPinLocation03
                                : HugeIcons.strokeRoundedInbox,
                      ),
                      label: isTaxiDriver ? 'Rides'.tr() : "Orders".tr(),
                    ),
                    BottomNavigationBarItem(
                      icon: HugeIcon(icon: HugeIcons.strokeRoundedPieChart03),
                      activeIcon: HugeIcon(
                        icon: HugeIcons.strokeRoundedPieChart02,
                      ),
                      label: 'Stats'.tr(),
                    ),
                    BottomNavigationBarItem(
                      icon: HugeIcon(icon: HugeIcons.strokeRoundedChartBarLine),
                      activeIcon: HugeIcon(
                        icon: HugeIcons.strokeRoundedChartBarLine,
                      ),
                      label: 'Report'.tr(),
                    ),
                    BottomNavigationBarItem(
                      icon: HugeIcon(icon: HugeIcons.strokeRoundedMenu01),
                      activeIcon: HugeIcon(icon: HugeIcons.strokeRoundedMenu02),
                      label: 'More'.tr(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
