import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/constants/app_ui_settings.dart';
import 'package:fuodz/constants/sizes.dart';
import 'package:fuodz/extensions/dynamic.dart';
import 'package:fuodz/models/delivery_address.dart';
import 'package:fuodz/models/order.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/utils/ui_spacer.dart';
import 'package:fuodz/view_models/order_details.vm.dart';
import 'package:fuodz/views/pages/order/widgets/driver_cash_delivery_note.view.dart';
import 'package:fuodz/views/pages/order/widgets/order_actions.dart';
import 'package:fuodz/views/pages/order/widgets/order_address.view.dart';
import 'package:fuodz/views/pages/order/widgets/order_payment_info.view.dart';
import 'package:fuodz/views/pages/order/widgets/recipient_info.dart';
import 'package:fuodz/views/pages/order/widgets/topup_customer_wallet.button.dart';

import 'package:fuodz/widgets/base.page.dart';
import 'package:fuodz/widgets/busy_indicator.dart';
import 'package:fuodz/widgets/buttons/custom_button.dart';
import 'package:fuodz/widgets/cards/amount_tile.dart';
import 'package:fuodz/widgets/cards/order_summary.dart';
import 'package:fuodz/widgets/currency_hstack.dart';
import 'package:fuodz/widgets/custom_list_view.dart';
import 'package:fuodz/widgets/list_items/order_product.list_item.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({required this.order, Key? key}) : super(key: key);

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ViewModelBuilder<OrderDetailsViewModel>.reactive(
        viewModelBuilder: () => OrderDetailsViewModel(context, order),
        onViewModelReady: (vm) => vm.initialise(),
        builder: (context, vm, child) {
          return BasePage(
            title: "Order Details".tr(),
            showAppBar: true,
            showLeadingAction: true,
            onBackPressed: vm.onBackPressed,
            isLoading: vm.isBusy,
            backgroundColor: context.theme.colorScheme.background,
            elevation: 0,
            actions: [TopupCustomerWalletButton(vm.order)],
            body:
                vm.isBusy
                    ? BusyIndicator().centered()
                    : SingleChildScrollView(
                      padding: EdgeInsets.all(Sizes.paddingSizeDefault),
                      child: VStack([
                        // SECTION 1: Status & Payment
                        _buildSection(
                          context,
                          children: [
                            HStack([
                              VStack([
                                "Order Code".tr().text.sm.gray500.make(),
                                "#${vm.order.code}".text.xl.bold.make(),
                              ]).expand(),
                              // Total Amount
                              CurrencyHStack([
                                AppStrings.currencySymbol.text.lg.bold.make(),
                                "${(vm.order.total ?? 0.00).currencyValueFormat()}"
                                    .text
                                    .xl2
                                    .bold
                                    .make(),
                              ]),
                            ]),
                            UiSpacer.divider().py12(),

                            VStack([
                              "Status".tr().text.sm.gray500.make(),
                              "${vm.order.status.tr().capitalized}".text
                                  .color(
                                    AppColor.getStausColor(vm.order.status),
                                  )
                                  .bold
                                  .make(),
                            ]),
                            Sizes.paddingSizeMedium.heightBox,
                            OrderPaymentInfoView(vm),
                          ],
                        ),

                        // SECTION 2: Locations
                        _buildSection(
                          context,
                          children: [
                            "Locations".tr().text.lg.semiBold.make().pOnly(
                              bottom: 12,
                            ),
                            OrderAddressView(vm),
                          ],
                        ),

                        // SECTION 3: Vendor
                        _buildSection(
                          context,
                          children: [
                            "Vendor".tr().text.lg.semiBold.make(),
                            12.heightBox,
                            HStack([
                              VStack([
                                vm.order.vendor!.name.text.xl.medium.make(),
                                "${vm.order.vendor?.address}".text.sm.gray500
                                    .make(),
                              ]).expand(),
                              // Actions
                              if (vm.order.canChatVendor &&
                                  AppUISettings.canCallVendor)
                                IconButton(
                                  icon: HugeIcon(icon: HugeIcons.strokeRoundedCall02,
                                    color: AppColor.primaryColor,
                                  ),
                                  onPressed: vm.callVendor,
                                ),
                              IconButton(
                                icon: HugeIcon(icon: HugeIcons.strokeRoundedNavigation03,
                                  color: AppColor.primaryColor,
                                ),
                                onPressed:
                                    (vm.order.vendor == null ||
                                            vm.order.vendor?.latitude == null)
                                        ? null
                                        : () => vm.routeToLocation(
                                          DeliveryAddress(
                                            name: vm.order.vendor!.name,
                                            latitude: double.parse(
                                              vm.order.vendor!.latitude,
                                            ),
                                            longitude: double.parse(
                                              vm.order.vendor!.longitude,
                                            ),
                                          ),
                                        ),
                              ),
                            ]),
                            if (vm.order.canChatVendor &&
                                AppUISettings.canVendorChat)
                              CustomButton(
                                icon: HugeIcons.strokeRoundedMessage01,
                                iconColor: Colors.white,
                                title: "Chat with vendor".tr(),
                                color: AppColor.primaryColor,
                                onPressed: vm.chatVendor,
                              ).h(Vx.dp48).py12(),
                          ],
                        ),

                        // SECTION 4: Customer
                        _buildSection(
                          context,
                          children: [
                            "Customer".tr().text.lg.semiBold.make(),
                            12.heightBox,
                            HStack([
                              vm.order.user.name.text.xl.medium.make().expand(),
                              if (vm.order.canChatCustomer &&
                                  AppUISettings.canCallCustomer)
                                IconButton(
                                  icon: HugeIcon(icon: HugeIcons.strokeRoundedCall02,
                                    color: AppColor.primaryColor,
                                  ),
                                  onPressed: vm.callCustomer,
                                ),
                            ]),
                            if (vm.order.canChatCustomer &&
                                AppUISettings.canCustomerChat)
                              CustomButton(
                                icon: HugeIcons.strokeRoundedMessage01,
                                iconColor: Colors.white,
                                title: "Chat with customer".tr(),
                                color: AppColor.primaryColor,
                                onPressed: vm.chatCustomer,
                              ).h(Vx.dp48).py12(),

                            if (vm.order.recipientName != null) ...[
                              UiSpacer.divider().py12(),
                              RecipientInfo(
                                callRecipient: vm.callRecipient,
                                order: vm.order,
                              ),
                            ],
                          ],
                        ),

                        // SECTION 5: Details & Products
                        _buildSection(
                          context,
                          children: [
                            "Order Details".tr().text.lg.semiBold.make(),
                            12.heightBox,
                            if (vm.order.note.isNotEmpty) ...[
                              "Note".tr().text.sm.gray500.make(),
                              "${vm.order.note}".text.italic.make().pOnly(
                                bottom: 12,
                              ),
                            ],
                            (vm.order.isPackageDelivery
                                    ? "Package Details"
                                    : "Products")
                                .tr()
                                .text
                                .medium
                                .make(),
                            8.heightBox,
                            vm.order.isPackageDelivery
                                ? VStack([
                                  AmountTile(
                                    "Package Type".tr(),
                                    vm.order.packageType!.name,
                                  ),
                                  AmountTile(
                                    "Width".tr(),
                                    "${vm.order.width} cm",
                                  ),
                                  AmountTile(
                                    "Length".tr(),
                                    "${vm.order.length} cm",
                                  ),
                                  AmountTile(
                                    "Height".tr(),
                                    "${vm.order.height} cm",
                                  ),
                                  AmountTile(
                                    "Weight".tr(),
                                    "${vm.order.weight} kg",
                                  ),
                                ])
                                : CustomListView(
                                  noScrollPhysics: true,
                                  dataSet: vm.order.orderProducts ?? [],
                                  separatorBuilder:
                                      (_, __) => UiSpacer.divider().py8(),
                                  itemBuilder: (context, index) {
                                    final orderProduct =
                                        vm.order.orderProducts![index];
                                    return OrderProductListItem(
                                      orderProduct: orderProduct,
                                    );
                                  },
                                ),
                          ],
                        ),

                        // Cash Notice
                        CheckoutDriverCashDeliveryNoticeView(),

                        // SECTION 6: Summary
                        OrderSummary(
                          subTotal: vm.order.subTotal,
                          discount: vm.order.discount,
                          deliveryFee: vm.order.deliveryFee,
                          tax: vm.order.tax,
                          driverTip: vm.order.tip,
                          vendorTax: vm.order.taxRate.toString(),
                          total: vm.order.total!,
                          fees: vm.order.fees ?? [],
                        ),

                        100.heightBox,
                      ], spacing: 16),
                    ),
            bottomSheet: OrderActions(
              order: vm.order,
              canChatCustomer: vm.order.canChatCustomer,
              busy: vm.isBusy || vm.busy(vm.order),
              processOrderCompletion: vm.initiateOrderCompletion,
              processOrderEnroute: vm.processOrderEnroute,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Sizes.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: VStack(children),
    );
  }
}
