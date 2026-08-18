import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_ui_settings.dart';
import 'package:fuodz/constants/sizes.dart';
import 'package:fuodz/view_models/profile.vm.dart';
import 'package:fuodz/views/pages/profile/finance.page.dart';
import 'package:fuodz/views/pages/profile/legal.page.dart';
import 'package:fuodz/views/pages/profile/support.page.dart';
import 'package:fuodz/views/pages/profile/widget/document_request.view.dart';
import 'package:fuodz/views/pages/profile/widget/driver_type.switch.dart';
import 'package:fuodz/views/pages/subscription/subscription.page.dart';
import 'package:fuodz/views/pages/vehicle/vehicles.page.dart';
import 'package:fuodz/widgets/base.page.dart';
import 'package:fuodz/widgets/cards/profile.card.dart';
import 'package:fuodz/widgets/menu_item.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ViewModelBuilder<ProfileViewModel>.reactive(
        viewModelBuilder: () => ProfileViewModel(context),
        onViewModelReady: (model) => model.initialise(),
        builder: (context, model, child) {
          return BasePage(
            backgroundColor: context.theme.colorScheme.surface,
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: VStack([
                // Header
                "Settings".tr().text.xl3.bold.make(),
                "Profile & App Settings".tr().text.base.gray500.make(),
                24.heightBox,

                // Profile Card
                ProfileCard(model),
                24.heightBox,

                // Driver Type Switch
                if (AppUISettings.enableDriverTypeSwitch) ...[
                  DriverTypeSwitch(),
                  24.heightBox,
                ],

                // Document Verification
                DocumentRequestView(),
                24.heightBox,

                // Account Section
                _buildSectionTitle("Account".tr()),
                _buildMenuSection(
                  context,
                  children: [
                    //subscription
                    if (AppUISettings.enableDriverSubscription) ...[
                      MenuItem(
                        prefix: HugeIcon(
                          icon: HugeIcons.strokeRoundedLicense,
                        ),
                        title: "Subscription".tr(),
                        onPressed: () {
                          context.nextPage(SubscriptionPage());
                        },
                      ),
                    ],
                    if (AppUISettings.enableDriverTypeSwitch ||
                        model.currentUser.isTaxiDriver)
                      MenuItem(
                        prefix: HugeIcon(icon: HugeIcons.strokeRoundedCar02),
                        title: "Vehicle Details".tr(),
                        onPressed: () {
                          context.nextPage(VehiclesPage());
                        },
                      ),
                    MenuItem(
                      title: "Finance".tr(),
                      prefix: HugeIcon(icon: HugeIcons.strokeRoundedWallet01),
                      onPressed: () {
                        context.nextPage(FinancePage());
                      },
                      divider: false,
                    ),
                  ],
                ),
                24.heightBox,

                // General Section
                _buildSectionTitle("General".tr()),
                _buildMenuSection(
                  context,
                  children: [
                    MenuItem(
                      title: "Language".tr(),
                      prefix: HugeIcon(icon: HugeIcons.strokeRoundedGlobe02),
                      onPressed: model.changeLanguage,
                    ),
                    MenuItem(
                      title: "Theme".tr(),
                      suffix: Text(
                        AdaptiveTheme.of(context).mode.name.tr().capitalized,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.primaryColor,
                        ),
                      ),
                      prefix: HugeIcon(icon: HugeIcons.strokeRoundedPaintBoard),
                      onPressed: () {
                        AdaptiveTheme.of(context).toggleThemeMode();
                      },
                    ),
                    MenuItem(
                      title: "Notifications".tr(),
                      prefix: HugeIcon(
                        icon: HugeIcons.strokeRoundedNotification01,
                      ),
                      onPressed: model.openNotification,
                      divider: false,
                    ),
                  ],
                ),
                24.heightBox,

                // Support Section
                _buildSectionTitle("Support".tr()),
                _buildMenuSection(
                  context,
                  children: [
                    MenuItem(
                      title: "Rate & Review".tr(),
                      prefix: HugeIcon(icon: HugeIcons.strokeRoundedStar),
                      onPressed: model.openReviewApp,
                    ),
                    MenuItem(
                      title: "Faqs".tr(),
                      prefix: HugeIcon(icon: HugeIcons.strokeRoundedHelpCircle),
                      onPressed: model.openFaqs,
                    ),
                    MenuItem(
                      title: "Legal".tr(),
                      prefix: HugeIcon(icon: HugeIcons.strokeRoundedShield01),
                      onPressed: () {
                        context.nextPage(LegalPage());
                      },
                    ),
                    MenuItem(
                      title: "Support".tr(),
                      prefix: HugeIcon(
                        icon: HugeIcons.strokeRoundedCustomerSupport,
                      ),
                      onPressed: () {
                        context.nextPage(SupportPage());
                      },
                      divider: false,
                    ),
                  ],
                ),
                24.heightBox,

                // Logout
                MenuItem(
                      child: "Logout".tr().text.red500.make(),
                      prefix: HugeIcon(
                        icon: HugeIcons.strokeRoundedLogout01,
                        color: Colors.red,
                      ),
                      onPressed: model.logoutPressed,
                      divider: false,
                      suffix: SizedBox.shrink(), // No arrow for logout
                    ).box
                    .color(context.theme.cardColor)
                    .withRounded(value: 12)
                    .shadowSm
                    .make(),
                24.heightBox,
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return title.text.lg.semiBold.make().pOnly(bottom: 8, left: 4);
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Sizes.radiusDefault),
        child: Column(children: children),
      ),
    );
  }
}
