import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  _SalesReportScreenState createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  String _selectedPeriod = 'Daily';
  DateTimeRange? _selectedDateRange;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

  Stream<QuerySnapshot> _getReceiptsStream() {
    final now = DateTime.now();
    if (_selectedDateRange != null) {
      return _firestore
          .collection('orders')
          .where('timestamp',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(_selectedDateRange!.start))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(_selectedDateRange!.end))
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
    switch (_selectedPeriod) {
      case 'Daily':
        return _firestore
            .collection('orders')
            .where('timestamp',
                isGreaterThanOrEqualTo:
                    Timestamp.fromDate(DateTime(now.year, now.month, now.day)))
            .where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(
                    DateTime(now.year, now.month, now.day + 1)))
            .orderBy('timestamp', descending: true)
            .snapshots();
      case 'Weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return _firestore
            .collection('orders')
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
            .where('timestamp',
                isLessThanOrEqualTo:
                    Timestamp.fromDate(startOfWeek.add(Duration(days: 7))))
            .orderBy('timestamp', descending: true)
            .snapshots();
      case 'Monthly':
        return _firestore
            .collection('orders')
            .where('timestamp',
                isGreaterThanOrEqualTo:
                    Timestamp.fromDate(DateTime(now.year, now.month, 1)))
            .where('timestamp',
                isLessThanOrEqualTo:
                    Timestamp.fromDate(DateTime(now.year, now.month + 1, 0)))
            .orderBy('timestamp', descending: true)
            .snapshots();
      default:
        return _firestore
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots();
    }
  }

  Future<Map<String, double>> _calculateIncome() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    double dailyIncome = 0.0;
    double weeklyIncome = 0.0;
    double monthlyIncome = 0.0;

    final snapshot = await _firestore
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final receiptDate = (data['timestamp'] as Timestamp).toDate();
      final total = (data['total'] as num).toDouble();
      if (receiptDate.year == now.year &&
          receiptDate.month == now.month &&
          receiptDate.day == now.day) {
        dailyIncome += total;
      }
      if (receiptDate.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
          receiptDate.isBefore(startOfWeek.add(Duration(days: 7)))) {
        weeklyIncome += total;
      }
      if (receiptDate.year == now.year && receiptDate.month == now.month) {
        monthlyIncome += total;
      }
    }

    return {
      'daily': dailyIncome,
      'weekly': weeklyIncome,
      'monthly': monthlyIncome,
    };
  }

  Future<List<Map<String, dynamic>>> _generateSalesReport() async {
    final snapshot = await _getReceiptsStream().first;
    final receipts = snapshot.docs
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'docId': doc.id})
        .toList();
    final now = DateTime.now();
    final report = <Map<String, dynamic>>[];

    if (_selectedPeriod == 'Daily' || _selectedDateRange != null) {
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (var receipt in receipts) {
        final date = (receipt['timestamp'] as Timestamp).toDate();
        final dateKey = DateFormat('MMM dd, yyyy').format(date);
        grouped[dateKey] = grouped[dateKey] ?? [];
        grouped[dateKey]!.add(receipt);
      }
      grouped.forEach((date, receipts) {
        final totalSales =
            receipts.fold(0.0, (sum, r) => sum + (r['total'] as num));
        final transactions = receipts.length;
        report.add({
          'date': date,
          'totalSales': totalSales,
          'transactions': transactions,
          'avgTransaction': transactions > 0 ? totalSales / transactions : 0.0,
        });
      });
    } else if (_selectedPeriod == 'Weekly') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      for (int i = 0; i < 4; i++) {
        final weekStart = startOfWeek.subtract(Duration(days: 7 * i));
        final weekEnd = weekStart.add(Duration(days: 6));
        final receiptsInWeek = receipts.where((r) {
          final date = (r['timestamp'] as Timestamp).toDate();
          return date.isAfter(weekStart.subtract(Duration(days: 1))) &&
              date.isBefore(weekEnd.add(Duration(days: 1)));
        }).toList();
        if (receiptsInWeek.isNotEmpty) {
          final totalSales =
              receiptsInWeek.fold(0.0, (sum, r) => sum + (r['total'] as num));
          final transactions = receiptsInWeek.length;
          report.add({
            'date': 'Week of ${DateFormat('MMM dd').format(weekStart)}',
            'totalSales': totalSales,
            'transactions': transactions,
            'avgTransaction':
                transactions > 0 ? totalSales / transactions : 0.0,
          });
        }
      }
    } else if (_selectedPeriod == 'Monthly') {
      for (int i = 0; i < 3; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        final receiptsInMonth = receipts.where((r) {
          final date = (r['timestamp'] as Timestamp).toDate();
          return date.year == month.year && date.month == month.month;
        }).toList();
        if (receiptsInMonth.isNotEmpty) {
          final totalSales =
              receiptsInMonth.fold(0.0, (sum, r) => sum + (r['total'] as num));
          final transactions = receiptsInMonth.length;
          report.add({
            'date': DateFormat('MMMM yyyy').format(month),
            'totalSales': totalSales,
            'transactions': transactions,
            'avgTransaction':
                transactions > 0 ? totalSales / transactions : 0.0,
          });
        }
      }
    }
    return report;
  }

  void _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedPeriod = 'Custom';
      });
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final snapshot = await _getReceiptsStream().first;
      final receipts = snapshot.docs
          .map(
              (doc) => {...doc.data() as Map<String, dynamic>, 'docId': doc.id})
          .toList();

      List<List<dynamic>> csvData = [
        ['Date', 'Total Sales (P)', 'Transactions', 'Avg. Transaction (P)'],
      ];

      final report = await _generateSalesReport();
      for (var entry in report) {
        csvData.add([
          entry['date'],
          entry['totalSales'].toStringAsFixed(2),
          entry['transactions'],
          entry['avgTransaction'].toStringAsFixed(2),
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csvString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download',
            'sales_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error exporting to CSV: $e',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: festiveRed,
        ),
      );
    }
  }

  Future<void> _printSalesReport() async {
    final pdf = pw.Document();
    try {
      final report = await _generateSalesReport();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Sales Report - $_selectedPeriod',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FractionColumnWidth(0.4),
                    1: const pw.FractionColumnWidth(0.2),
                    2: const pw.FractionColumnWidth(0.2),
                    3: const pw.FractionColumnWidth(0.2),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text('Date',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Total Sales (P)',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Transactions',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Avg. Transaction (P)',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    ...report.map((entry) => pw.TableRow(
                          children: [
                            pw.Text(entry['date'],
                                style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(entry['totalSales'].toStringAsFixed(2),
                                style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(entry['transactions'].toString(),
                                style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(entry['avgTransaction'].toStringAsFixed(2),
                                style: const pw.TextStyle(fontSize: 10)),
                          ],
                        )),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error printing report: $e',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: festiveRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        title: Row(
          children: [
            TextWidget(
              text: 'Sales Report',
              fontSize: 20,
              fontFamily: 'Bold',
              color: Colors.white,
              isBold: true,
            ),
            const Spacer(),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: _selectedPeriod,
                dropdownColor: bayanihanBlue,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: ['Daily', 'Weekly', 'Monthly', 'Custom'].map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: TextWidget(
                      text: period,
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                    if (value != 'Custom') {
                      _selectedDateRange = null;
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            ButtonWidget(
              radius: 8,
              width: 200,
              color: Colors.white12,
              textColor: Colors.white,
              label: 'Custom Date',
              onPressed: () => _selectDateRange(context),
              fontSize: 12,
            ),
            const SizedBox(width: 12),
            ButtonWidget(
              radius: 8,
              width: 200,
              color: Colors.white12,
              textColor: Colors.white,
              label: 'Export CSV',
              onPressed: _exportToCSV,
              fontSize: 12,
            ),
            const SizedBox(width: 12),
            ButtonWidget(
              radius: 8,
              width: 200,
              color: Colors.white12,
              textColor: Colors.white,
              label: 'Print Report',
              onPressed: _printSalesReport,
              fontSize: 12,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: FutureBuilder<Map<String, double>>(
                future: _calculateIncome(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: TextWidget(
                        text: 'Error: ${snapshot.error}',
                        fontSize: 16,
                        fontFamily: 'Regular',
                        color: festiveRed,
                      ),
                    );
                  }
                  final income = snapshot.data ??
                      {'daily': 0.0, 'weekly': 0.0, 'monthly': 0.0};
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: 'Income Summary',
                        fontSize: 18,
                        fontFamily: 'Bold',
                        color: primaryBlue,
                        isBold: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildIncomeCard(
                              title: 'Daily Income',
                              amount: income['daily']!,
                              icon: Icons.today,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildIncomeCard(
                              title: 'Weekly Income',
                              amount: income['weekly']!,
                              icon: Icons.calendar_view_week,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildIncomeCard(
                        title: 'Monthly Income',
                        amount: income['monthly']!,
                        icon: Icons.calendar_month,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: 'Sales Report',
                        fontSize: 18,
                        fontFamily: 'Bold',
                        color: primaryBlue,
                        isBold: true,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _getReceiptsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: TextWidget(
                                  text: 'Error: ${snapshot.error}',
                                  fontSize: 16,
                                  fontFamily: 'Regular',
                                  color: festiveRed,
                                ),
                              );
                            }
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            return FutureBuilder<List<Map<String, dynamic>>>(
                              future: _generateSalesReport(),
                              builder: (context, reportSnapshot) {
                                if (reportSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (reportSnapshot.hasError) {
                                  return Center(
                                    child: TextWidget(
                                      text: 'Error: ${reportSnapshot.error}',
                                      fontSize: 16,
                                      fontFamily: 'Regular',
                                      color: festiveRed,
                                    ),
                                  );
                                }
                                final salesReport = reportSnapshot.data ?? [];
                                return SingleChildScrollView(
                                  child: DataTable(
                                    columnSpacing: 16,
                                    dataRowHeight: 60,
                                    headingRowColor: WidgetStatePropertyAll(
                                        primaryBlue.withOpacity(0.1)),
                                    columns: [
                                      DataColumn(
                                        label: TextWidget(
                                          text: 'Date',
                                          fontSize: 16,
                                          fontFamily: 'Bold',
                                          color: primaryBlue,
                                        ),
                                      ),
                                      DataColumn(
                                        label: TextWidget(
                                          text: 'Total Sales (P)',
                                          fontSize: 16,
                                          fontFamily: 'Bold',
                                          color: primaryBlue,
                                        ),
                                      ),
                                      DataColumn(
                                        label: TextWidget(
                                          text: 'Transactions',
                                          fontSize: 16,
                                          fontFamily: 'Bold',
                                          color: primaryBlue,
                                        ),
                                      ),
                                      DataColumn(
                                        label: TextWidget(
                                          text: 'Avg. Transaction (P)',
                                          fontSize: 16,
                                          fontFamily: 'Bold',
                                          color: primaryBlue,
                                        ),
                                      ),
                                    ],
                                    rows: salesReport.map((report) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            TextWidget(
                                              text: report['date'],
                                              fontSize: 14,
                                              fontFamily: 'Regular',
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          DataCell(
                                            TextWidget(
                                              text: report['totalSales']
                                                  .toStringAsFixed(2),
                                              fontSize: 14,
                                              fontFamily: 'Regular',
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          DataCell(
                                            TextWidget(
                                              text: report['transactions']
                                                  .toString(),
                                              fontSize: 14,
                                              fontFamily: 'Regular',
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          DataCell(
                                            TextWidget(
                                              text: report['avgTransaction']
                                                  .toStringAsFixed(2),
                                              fontSize: 14,
                                              fontFamily: 'Regular',
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCard({
    required String title,
    required double amount,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primaryBlue.withOpacity(0.1),
              child: Icon(
                icon,
                color: primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: title,
                  fontSize: 16,
                  fontFamily: 'Medium',
                  color: Colors.grey[800],
                ),
                TextWidget(
                  text: 'P${amount.toStringAsFixed(2)}',
                  fontSize: 20,
                  fontFamily: 'Bold',
                  color: primaryBlue,
                  isBold: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
