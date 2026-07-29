import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/constants/app_images.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/utils/ui_spacer.dart';
import 'package:fuodz/view_models/login.view_model.dart';
import 'package:fuodz/views/pages/auth/login/compain_login_type.view.dart';
import 'package:fuodz/views/pages/auth/login/email_login.view.dart';
import 'package:fuodz/views/pages/auth/login/otp_login.view.dart';
import 'package:fuodz/widgets/base.page.dart';

import 'package:localize_and_translate/localize_and_translate.dart';

import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

import 'login/scan_login.view.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<LoginViewModel>.reactive(
      viewModelBuilder: () => LoginViewModel(context),
      onViewModelReady: (model) => model.initialise(),
      builder: (context, model, child) {
        return BasePage(
          backgroundColor: context.theme.colorScheme.surface,
          body: VStack([
                UiSpacer.vSpace(6 * context.percentHeight),
                // Header
                VStack(
                  [
                    Image.asset(AppImages.appLogo)
                        .wh(90, 90)
                        .box
                        .roundedFull
                        .shadowSm
                        .clip(Clip.antiAlias)
                        .make(),
                    20.heightBox,
                    "Welcome Back".tr().text.xl3.bold.make(),
                    "Login to continue".tr().text.base.gray500.make(),
                  ],
                  crossAlignment: CrossAxisAlignment.center,
                  alignment: MainAxisAlignment.center,
                ).wFull(context),

                40.heightBox,

                //form
                //LOGIN Section
                //both login type
                if (AppStrings.enableOTPLogin && AppStrings.enableEmailLogin)
                  CombinedLoginTypeView(model),
                //only email login
                if (AppStrings.enableEmailLogin && !AppStrings.enableOTPLogin)
                  EmailLoginView(model),
                //only otp login
                if (AppStrings.enableOTPLogin && !AppStrings.enableEmailLogin)
                  OTPLoginView(model),

                ScanLoginView(model),
                20.heightBox,

                //registration link
                Visibility(
                  visible: AppStrings.partnersCanRegister,
                  child: OutlinedButton(
                    onPressed: model.openRegistrationlink,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.primaryColor,
                      side: BorderSide(color: AppColor.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: "Become a partner".tr().text.bold.make(),
                  ).wFull(context),
                ),

                //
              ])
              .wFull(context)
              .p20()
              .scrollVertical()
              .pOnly(bottom: context.mq.viewInsets.bottom),
        );
      },
    );
  }
}
