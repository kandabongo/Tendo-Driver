import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/models/notification.dart';
import 'package:fuodz/services/app.service.dart';
import 'package:fuodz/services/local_storage.service.dart';
import 'package:fuodz/services/notification.service.dart';
import 'package:fuodz/utils/utils.dart';
import 'package:fuodz/view_models/home.vm.dart';
import 'package:fuodz/views/pages/notification/notifications.page.dart';
import 'package:fuodz/widgets/busy_indicator.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

class OnlineOfflineFab extends StatelessWidget {
  const OnlineOfflineFab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(context),
      onViewModelReady: (homeVm) => homeVm.initialise(),
      builder: (context, homeVm, child) {
        //
        return HStack([
          "Active Orders".tr().text.xl2.semiBold.make().expand(),
          //
          if (homeVm.isBusy)
            BusyIndicator(color: AppColor.primaryColor).wh(35, 35),
          if (!homeVm.isBusy)
            AnimatedToggleSwitch<bool>.dual(
              current: AppService().driverIsOnline,
              first: false,
              second: true,
              height: 35,
              spacing: 28,
              borderWidth: 2,
              animationDuration: Duration(milliseconds: 300),
              style: ToggleStyle(
                borderColor: Colors.transparent,
                indicatorColor: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              styleBuilder: (state) {
                return ToggleStyle(
                  backgroundColor: state ? Colors.green : Colors.red,
                );
              },
              iconBuilder: (state) {
                return Icon(
                  state ? Icons.location_on : Icons.location_off,
                  color: state ? Colors.green : Colors.red,
                  size: 18,
                );
              },
              textBuilder: (state) {
                return Center(
                  child: Text(
                    state ? "Online".tr() : "Offline".tr(),
                    style: context.textTheme.bodyLarge!.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
              onChanged: (state) {
                print('turned ${state ? 'on' : 'off'}');
                homeVm.toggleOnlineStatus();
              },
            ).w(context.screenWidth * 0.32),

          // notification icon
          StreamBuilder<String?>(
            stream: LocalStorageService.rxPrefs!.getStringStream(
              AppStrings.notificationsKey,
            ),
            builder: (context, snapshot) {
              Widget icon = Icon(EvaIcons.bellOutline, size: 26);

              //get notifications count of unread notifications
              if (snapshot.hasData) {
                return FutureBuilder<List<NotificationModel>?>(
                  future: NotificationService.getNotifications(),
                  builder: (context, dataSet) {
                    //
                    int totalUnread = 0;
                    if (dataSet.hasData) {
                      totalUnread =
                          dataSet.data!
                              .where((element) => !element.read)
                              .toList()
                              .length;
                    }
                    //
                    if (totalUnread > 0) {
                      icon = icon.badge(
                        color: AppColor.primaryColor,
                        count: totalUnread,
                        textStyle: TextStyle(
                          color: Utils.textColorByTheme(),
                          fontSize: 12,
                        ),
                      );
                    }

                    //
                    return icon.p(4).onTap(() {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NotificationsPage(),
                        ),
                      );
                    });
                  },
                );
              } else {
                return icon.p(4).onTap(() {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NotificationsPage(),
                    ),
                  );
                });
              }
            },
          ),
        ], spacing: 8);
      },
    ).p(12).wFull(context);
  }
}
