import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/view_models/finance_report.vm.dart';
import 'package:fuodz/widgets/busy_indicator.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:velocity_x/velocity_x.dart';

class PayoutReportView extends StatelessWidget {
  const PayoutReportView({required this.vm, super.key});

  final FinanceReportViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Visibility(
          visible: vm.busy(vm.payoutReportDataSource),
          child: BusyIndicator().p20().centered(),
        ),

        //
        SmartRefresher(
          controller: vm.payoutsReportRefreshController,
          enablePullDown: true,
          enablePullUp: true,
          onRefresh: () {
            vm.fetchPayoutReport();
          },
          onLoading: () {
            vm.fetchPayoutReport(true);
          },
          child: DataTable2(
            minWidth: context.isMobileTypeTablet ? null : 600,
            fixedTopRows: 1,
            headingRowHeight: 44,
            dataRowHeight: 48,
            columnSpacing: 12,
            horizontalMargin: 8,
            columns: [
              DataColumn2(
                label: Text('S/N'.tr(), overflow: TextOverflow.ellipsis),
                fixedWidth: 55,
              ),
              DataColumn2(
                label: Text('Date'.tr(), overflow: TextOverflow.ellipsis),
              ),
              DataColumn2(
                label: Text(
                  'Amount'.tr() + " (${AppStrings.currencySymbol})",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataColumn2(
                label: Text('Status'.tr(), overflow: TextOverflow.ellipsis),
              ),
              DataColumn2(
                label: Text(
                  'Payment Account'.tr(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            rows: vm.payoutReportDataSource.rows,
            empty:
                vm.busy(vm.payoutReportDataSource)
                    ? null
                    : "No data".tr().text.gray400.makeCentered().p20(),
          ),
        ).expand(),
      ],
    );
  }
}
