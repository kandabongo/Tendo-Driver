import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fuodz/utils/ui_spacer.dart';
import 'package:fuodz/view_models/permission.vm.dart';
import 'package:fuodz/widgets/buttons/custom_button.dart';
import 'package:fuodz/widgets/buttons/custom_text_button.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:velocity_x/velocity_x.dart';

class RequestLocationPermissionView extends StatefulWidget {
  const RequestLocationPermissionView(this.vm, {Key? key}) : super(key: key);

  final PermissionViewModel vm;

  @override
  State<RequestLocationPermissionView> createState() =>
      _RequestLocationPermissionViewState();
}

class _RequestLocationPermissionViewState
    extends State<RequestLocationPermissionView> {
  @override
  Widget build(BuildContext context) {
    return VStack(
      [
        UiSpacer.vSpace(),
        "Location Permission".tr().text.xl3.extraBlack.center.makeCentered(),

        //more info
        VStack(
          [
            UiSpacer.vSpace(),
            "app_location_access_service_msg"
                .tr()
                .text
                .lg
                .wordSpacing(2)
                .center
                .makeCentered(),
            UiSpacer.vSpace(),
            "location_permission_reason_msg"
                .tr()
                .text
                .lg
                .wordSpacing(2)
                .center
                .makeCentered(),
            UiSpacer.vSpace(),
          ],
        ).scrollVertical().expand(),

        UiSpacer.vSpace(),
        CustomButton(
          shapeRadius: 25,
          title: "Next".tr(),
          onPressed: widget.vm.handleLocationPermission,
        ),
        UiSpacer.vSpace(10),
        Visibility(
          visible: !Platform.isIOS,
          child: CustomTextButton(
            title: "Skip".tr(),
            onPressed: widget.vm.nextStep,
          ).wFull(context),
        ),
        UiSpacer.vSpace(10),
      ],
    ).p32().safeArea();
  }
}
