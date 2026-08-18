import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/view_models/finance_report.vm.dart';
import 'package:fuodz/widgets/busy_indicator.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:velocity_x/velocity_x.dart';

class EarningsReportView extends StatelessWidget {
  const EarningsReportView({required this.vm, super.key});
  final FinanceReportViewModel vm;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Visibility(
          visible: vm.busy(vm.earningReportDataSource),
          child: BusyIndicator().p20().centered(),
        ),
        SmartRefresher(
          controller: vm.earningReportRefreshController,
          enablePullDown: true,
          enablePullUp: true,
          onRefresh: () {
            vm.fetchEarningsReport();
          },
          onLoading: () {
            vm.fetchEarningsReport(true);
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
                  'Earned'.tr() + " (${AppStrings.currencySymbol})",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataColumn2(
                label: Text(
                  'Commission'.tr() + " (${AppStrings.currencySymbol})",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataColumn2(
                label: Text(
                  'Balance'.tr() + " (${AppStrings.currencySymbol})",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            rows: vm.earningReportDataSource.rows,
            empty: vm.busy(vm.earningReportDataSource)
                ? null
                : "No data".tr().text.gray400.makeCentered().p20(),
          ),
        ).expand(),
      ],
    );
  }
}
