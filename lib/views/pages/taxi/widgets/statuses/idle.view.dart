import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/constants/sizes.dart';
import 'package:fuodz/services/auth.service.dart';
import 'package:fuodz/view_models/taxi/taxi.vm.dart';
import 'package:fuodz/views/pages/taxi/widgets/online_status_swipe.btn.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:measure_size/measure_size.dart';
import 'package:velocity_x/velocity_x.dart';

class IdleTaxiView extends StatefulWidget {
  const IdleTaxiView(this.taxiViewModel, {Key? key}) : super(key: key);

  final TaxiViewModel taxiViewModel;

  @override
  State<IdleTaxiView> createState() => _IdleTaxiViewState();
}

class _IdleTaxiViewState extends State<IdleTaxiView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: MeasureSize(
        onChange: (size) {
          widget.taxiViewModel.taxiGoogleMapManagerService.updateGoogleMapPadding(
            size.height + 10,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Sizes.radiusExtraLarge),
              topRight: Radius.circular(Sizes.radiusExtraLarge),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: VStack([
              // Pull Bar Indicator
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 50,
                  height: 4,
                  margin: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Status Header
              HStack([
                VStack([
                  "Current Status".tr().text.sm.gray500.medium.make(),
                  (widget.taxiViewModel.appService.driverIsOnline
                          ? "Online & Searching".tr()
                          : "Offline".tr())
                      .text
                      .xl2
                      .bold
                      .color(
                        widget.taxiViewModel.appService.driverIsOnline
                            ? Colors.green
                            : Colors.grey,
                      )
                      .make(),
                ]).expand(),
                // Status Icon/Indicator
                if (widget.taxiViewModel.appService.driverIsOnline)
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.2).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedWifi01,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ], alignment: MainAxisAlignment.spaceBetween).px20(),

              Divider(color: Colors.grey.withOpacity(0.1)),

              // Vehicle Details
              if (!widget.taxiViewModel.appService.driverIsOnline)
                VStack([
                  _buildDetailRow(
                    context,
                    icon: HugeIcons.strokeRoundedCar02,
                    label: "Vehicle".tr(),
                    value: "${AuthServices.driverVehicle!.vehicleType.name}",
                    subValue:
                        "${AuthServices.driverVehicle?.carModel.carMake?.name} ${AuthServices.driverVehicle?.carModel.name} (${AuthServices.driverVehicle?.color})",
                  ),
                  Sizes.paddingSizeMedium.heightBox,
                  _buildDetailRow(
                    context,
                    icon: HugeIcons.strokeRoundedLicense,
                    label: "License Plate".tr(),
                    value: "${AuthServices.driverVehicle?.regNo}",
                  ),
                  Sizes.paddingSizeMedium.heightBox,
                ]).px20(),

              // Swipe Button
              OnlineStatusSwipeButton(widget.taxiViewModel).px(10),
              0.heightBox,
            ], spacing: Sizes.paddingSizeSmall),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required dynamic icon,
    required String label,
    required String value,
    String? subValue,
  }) {
    return HStack([
      Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColor.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: HugeIcon(icon: icon, color: AppColor.primaryColor, size: 22),
      ),
      12.widthBox,
      VStack([
        label.text.xs.gray400.make(),
        value.text.lg.semiBold.make(),
        if (subValue != null) subValue.text.sm.gray500.make(),
      ]).expand(),
    ]);
  }
}
