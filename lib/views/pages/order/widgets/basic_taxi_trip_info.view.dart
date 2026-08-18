import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/constants/sizes.dart';
import 'package:fuodz/extensions/dynamic.dart';
import 'package:fuodz/models/order.dart';
import 'package:fuodz/utils/utils.dart';
import 'package:fuodz/widgets/currency_hstack.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:velocity_x/velocity_x.dart';

class BasicTaxiTripInfoView extends StatelessWidget {
  BasicTaxiTripInfoView(this.order, {Key? key}) : super(key: key);

  final Order order;

  @override
  Widget build(BuildContext context) {
    DateTime orderDateTime = order.createdAt;
    if (order.pickupTime != null &&
        order.pickupTime!.isNotEmpty &&
        !order.pickupTime!.contains('null')) {
      orderDateTime = Jiffy.parse(order.pickupTime!).dateTime;
    }
    return VxBox(
      child:
          VStack([
            //date, code, amount
            HStack([
              VStack([
                "${DateFormat("dd MMM y").format(orderDateTime)}".text.medium.lg
                    .make(),
                order.taxiStatus
                    .tr()
                    .capitalized
                    .text
                    .color(AppColor.getStausColor(order.status))
                    .medium
                    .xl
                    .make(),
              ]).expand(),
              //total amount
              VStack(
                [
                  "#${order.code}".text.light.make(),
                  CurrencyHStack([
                    "${order.taxiOrder!.currency != null ? order.taxiOrder!.currency!.symbol : AppStrings.currencySymbol}"
                        .text
                        .semiBold
                        .xl
                        .make(),
                    "${(order.total ?? 0.00).currencyValueFormat()}"
                        .text
                        .semiBold
                        .xl2
                        .make(),
                  ]),
                ],
                crossAlignment: CrossAxisAlignment.end,
                alignment: MainAxisAlignment.end,
              ),
            ], crossAlignment: CrossAxisAlignment.start),
            //pickup/dropoff
            Timeline.tileBuilder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              builder: TimelineTileBuilder.connected(
                itemCount: 2,
                contentsAlign: ContentsAlign.basic,
                nodePositionBuilder: (context, index) => 0.00,
                indicatorBuilder: (context, index) {
                  return DotIndicator(
                    color: AppColor.primaryColor,
                    size: 28,
                    child:
                        Icon(
                          index == 0
                              ? FlutterIcons.my_location_mdi
                              : FlutterIcons.location_pin_ent,
                          size: 20,
                          color: Utils.textColorByTheme(),
                        ).p4(),
                  );
                },
                connectorBuilder: (context, index, connectorType) {
                  return DashedLineConnector(
                    color: Colors.grey.shade600,
                    gap: 5,
                    space: 5,
                    indent: 5,
                  );
                },
                contentsBuilder: (context, index) {
                  final orderPointDateTime =
                      index == 0 ? orderDateTime : order.updatedAt;
                  String orderPointDateTimeString = Jiffy.parseFromDateTime(
                    orderPointDateTime,
                  ).format(pattern: "ddMMMyy hh:mma");
                  bool isPickup = index == 0;
                  final contextTextStyle = context.textTheme.bodyMedium!
                      .copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: AppTextSizes.xs,
                        color: Vx.gray600,
                      );
                  final contextTitleTextStyle = context.textTheme.bodyMedium!
                      .copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: AppTextSizes.sm,
                      );
                  return VStack([
                    //if created at is not null
                    HStack([
                      Text(
                        isPickup
                            ? "Pickup Location".tr()
                            : "Drop Off Location".tr(),
                        style: context.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ).expand(),

                      //time
                      Text(
                        orderPointDateTimeString,
                        style: context.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColor.primaryColor,
                        ),
                      ),
                    ]),
                    if (isPickup) ...[
                      if (order.taxiOrder!.pickupName != null)
                        Text(
                          order.taxiOrder!.pickupName!,
                          style: contextTitleTextStyle,
                        ),
                      Text(
                        order.taxiOrder!.pickupAddress,
                        style: contextTextStyle,
                      ),
                    ] else ...[
                      if (order.taxiOrder!.dropoffName != null)
                        Text(
                          order.taxiOrder!.dropoffName!,
                          style: contextTitleTextStyle,
                        ),
                      Text(
                        order.taxiOrder!.dropoffAddress,
                        style: contextTextStyle,
                      ),
                    ],
                  ]).p(Vx.dp20);
                },
              ),
            ),
          ]).px20().py12(),
    ).shadowXs.color(context.theme.colorScheme.surface).make();
  }
}
