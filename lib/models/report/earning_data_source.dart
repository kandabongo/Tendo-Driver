import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/extensions/dynamic.dart';

class EarningReportDataSource {
  EarningReportDataSource({List<Map<String, dynamic>> dataSet = const []}) {
    _rows = dataSet.asMap().entries.map<DataRow2>((entry) {
      final index = entry.key;
      final e = entry.value;
      return DataRow2(
        cells: [
          DataCell(Text("${index + 1}")),
          DataCell(Text("${e['date']}")),
          DataCell(Text("${e["total_earning"]}".currencyValueFormat())),
          DataCell(Text("${e["total_commission"]}".currencyValueFormat())),
          DataCell(Text("${e["total_balance"]}".currencyValueFormat())),
        ],
      );
    }).toList();
  }

  List<DataRow2> _rows = [];

  List<DataRow2> get rows => _rows;

  bool get isEmpty => _rows.isEmpty;
}
