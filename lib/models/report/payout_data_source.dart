import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/extensions/dynamic.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

class PayoutReportDataSource {
  PayoutReportDataSource({List<Map<String, dynamic>> dataSet = const []}) {
    _rows = dataSet.asMap().entries.map<DataRow2>((entry) {
      final index = entry.key;
      final e = entry.value;
      return DataRow2(
        cells: [
          DataCell(Text("${index + 1}")),
          DataCell(Text("${e['date']}")),
          DataCell(Text("${e['amount']}".currencyValueFormat())),
          DataCell(Text(e["status"].toString().tr())),
          DataCell(
            Text(
              (e["payment_account"] != null)
                  ? "${e["payment_account"]["name"]} - [${e["payment_account"]["number"]}]"
                  : "",
            ),
          ),
        ],
      );
    }).toList();
  }

  List<DataRow2> _rows = [];

  List<DataRow2> get rows => _rows;

  bool get isEmpty => _rows.isEmpty;
}
