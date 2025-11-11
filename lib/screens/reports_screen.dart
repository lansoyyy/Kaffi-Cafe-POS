import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/utils/branch_service.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import 'package:fl_chart/fl_chart.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  _SalesReportScreenState createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  String _selectedPeriod = 'Daily';
  DateTimeRange? _selectedDateRange;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentBranch;

  @override
  void initState() {
    super.initState();
    _getCurrentBranch();
  }

  Future<void> _getCurrentBranch() async {
    final currentBranch = await BranchService.getSelectedBranch();
    if (mounted) {
      setState(() {
        _currentBranch = currentBranch;
      });
    }
  }

  Stream<QuerySnapshot> _getReceiptsStream() {
    final now = DateTime.now();
    if (_selectedDateRange != null) {
      return _firestore
          .collection('orders')
          .where('branch', isEqualTo: _currentBranch)
          .where('timestamp',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(_selectedDateRange!.start))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(
                  _selectedDateRange!.end.add(Duration(days: 1))))
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
    switch (_selectedPeriod) {
      case 'Daily':
        return _firestore
            .collection('orders')
            .where('branch', isEqualTo: _currentBranch)
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
            .where('branch', isEqualTo: _currentBranch)
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
            .where('branch', isEqualTo: _currentBranch)
            .where('timestamp',
                isGreaterThanOrEqualTo:
                    Timestamp.fromDate(DateTime(now.year, now.month, 1)))
            .where('timestamp',
                isLessThanOrEqualTo:
                    Timestamp.fromDate(DateTime(now.year, now.month + 1, 1)))
            .orderBy('timestamp', descending: true)
            .snapshots();
      default:
        return _firestore
            .collection('orders')
            .where('branch', isEqualTo: _currentBranch)
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

    // Get daily income
    final dailySnapshot = await _firestore
        .collection('orders')
        .where('branch', isEqualTo: _currentBranch)
        .where('timestamp',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(DateTime(now.year, now.month, now.day)))
        .where('timestamp',
            isLessThanOrEqualTo:
                Timestamp.fromDate(DateTime(now.year, now.month, now.day + 1)))
        .get();

    for (var doc in dailySnapshot.docs) {
      final data = doc.data();
      final total = (data['total'] as num).toDouble();
      dailyIncome += total;
    }

    // Get weekly income
    final weeklySnapshot = await _firestore
        .collection('orders')
        .where('branch', isEqualTo: _currentBranch)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .where('timestamp',
            isLessThanOrEqualTo:
                Timestamp.fromDate(startOfWeek.add(Duration(days: 7))))
        .get();

    for (var doc in weeklySnapshot.docs) {
      final data = doc.data();
      final total = (data['total'] as num).toDouble();
      weeklyIncome += total;
    }

    // Get monthly income
    final monthlySnapshot = await _firestore
        .collection('orders')
        .where('branch', isEqualTo: _currentBranch)
        .where('timestamp',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(DateTime(now.year, now.month, 1)))
        .where('timestamp',
            isLessThanOrEqualTo:
                Timestamp.fromDate(DateTime(now.year, now.month + 1, 1)))
        .get();

    for (var doc in monthlySnapshot.docs) {
      final data = doc.data();
      final total = (data['total'] as num).toDouble();
      monthlyIncome += total;
    }

    return {
      'daily': dailyIncome,
      'weekly': weeklyIncome,
      'monthly': monthlyIncome,
    };
  }

  Future<Map<String, dynamic>> _calculatePaymentBreakdown() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Determine date range based on selected period
    DateTime startDate, endDate;

    if (_selectedDateRange != null) {
      startDate = _selectedDateRange!.start;
      endDate = _selectedDateRange!.end.add(Duration(days: 1));
    } else {
      switch (_selectedPeriod) {
        case 'Daily':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day + 1);
          break;
        case 'Weekly':
          startDate = startOfWeek;
          endDate = startOfWeek.add(Duration(days: 7));
          break;
        case 'Monthly':
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day + 1);
      }
    }

    // Get orders within the date range
    final snapshot = await _firestore
        .collection('orders')
        .where('branch', isEqualTo: _currentBranch)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    double cashTotal = 0.0;
    double gcashTotal = 0.0;
    int dineInCount = 0;
    int pickupCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final total = (data['total'] as num).toDouble();
      final paymentMethod = data['paymentMethod'] as String?;
      final orderType = data['orderType'] as String?;

      // Payment method breakdown
      if (paymentMethod == 'Cash') {
        cashTotal += total;
      } else if (paymentMethod == 'GCash') {
        gcashTotal += total;
      }

      // Order type breakdown
      if (orderType == 'Dine in') {
        dineInCount++;
      } else if (orderType == 'Pickup') {
        pickupCount++;
      }
    }

    return {
      'paymentMethods': {
        'Cash': cashTotal,
        'GCash': gcashTotal,
      },
      'orderTypes': {
        'Dine in': dineInCount,
        'Pickup': pickupCount,
      },
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
        final totalSales = receipts.fold(
            0.0, (sum, r) => sum + (r['total'] as num).toDouble());
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
          final totalSales = receiptsInWeek.fold(
              0.0, (sum, r) => sum + (r['total'] as num).toDouble());
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
        final nextMonth = DateTime(now.year, now.month - i + 1, 1);
        final receiptsInMonth = receipts.where((r) {
          final date = (r['timestamp'] as Timestamp).toDate();
          return date.isAfter(month.subtract(Duration(days: 1))) &&
              date.isBefore(nextMonth);
        }).toList();
        if (receiptsInMonth.isNotEmpty) {
          final totalSales = receiptsInMonth.fold(
              0.0, (sum, r) => sum + (r['total'] as num).toDouble());
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

  // Methods for fetching chart data
  Future<List<Map<String, dynamic>>> _getDailyIncomeData() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> dailyData = [];

    // Get data for the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final nextDate = date.add(Duration(days: 1));

      final snapshot = await _firestore
          .collection('orders')
          .where('branch', isEqualTo: _currentBranch)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(nextDate))
          .get();

      double totalIncome = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final total = (data['total'] as num).toDouble();
        totalIncome += total;
      }

      dailyData.add({
        'date': DateFormat('MMM dd').format(date),
        'income': totalIncome,
      });
    }

    return dailyData;
  }

  Future<List<Map<String, dynamic>>> _getMonthlyIncomeData() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> monthlyData = [];

    // Get data for the last 6 months
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      final snapshot = await _firestore
          .collection('orders')
          .where('branch', isEqualTo: _currentBranch)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(month))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(nextMonth))
          .get();

      double totalIncome = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final total = (data['total'] as num).toDouble();
        totalIncome += total;
      }

      monthlyData.add({
        'month': DateFormat('MMM yyyy').format(month),
        'income': totalIncome,
      });
    }

    return monthlyData;
  }

  Future<List<Map<String, dynamic>>> _getOrderTypeData() async {
    final now = DateTime.now();
    DateTime startDate, endDate;

    if (_selectedDateRange != null) {
      startDate = _selectedDateRange!.start;
      endDate = _selectedDateRange!.end.add(Duration(days: 1));
    } else {
      switch (_selectedPeriod) {
        case 'Daily':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day + 1);
          break;
        case 'Weekly':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          startDate = startOfWeek;
          endDate = startOfWeek.add(Duration(days: 7));
          break;
        case 'Monthly':
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day + 1);
      }
    }

    final snapshot = await _firestore
        .collection('orders')
        .where('branch', isEqualTo: _currentBranch)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    int dineInCount = 0;
    int pickupCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final orderType = data['orderType'] as String?;

      if (orderType == 'Dine in') {
        dineInCount++;
      } else if (orderType == 'Pickup') {
        pickupCount++;
      }
    }

    return [
      {'type': 'Dine in', 'count': dineInCount},
      {'type': 'Pickup', 'count': pickupCount},
    ];
  }

  // Methods for fetching best sellers data
  Future<List<Map<String, dynamic>>> _getBestSellersData(String period) async {
    final now = DateTime.now();
    DateTime startDate, endDate;

    switch (period) {
      case 'Daily':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day + 1);
        break;
      case 'Weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startDate = startOfWeek;
        endDate = startOfWeek.add(Duration(days: 7));
        break;
      case 'Monthly':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day + 1);
    }

    final snapshot = await _firestore
        .collection('orders')
        .where('branch', isEqualTo: _currentBranch)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    Map<String, Map<String, dynamic>> itemSales = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final items = data['items'] as List<dynamic>;

      for (var item in items) {
        final itemName = item['name'] as String;
        final quantity = item['quantity'] as int;
        final price = (item['price'] as num).toDouble();
        final total = price * quantity;

        if (itemSales.containsKey(itemName)) {
          itemSales[itemName]!['quantity'] += quantity;
          itemSales[itemName]!['total'] += total;
        } else {
          itemSales[itemName] = {
            'name': itemName,
            'quantity': quantity,
            'price': price,
            'total': total,
          };
        }
      }
    }

    // Sort by quantity and get top 5
    final sortedItems = itemSales.values.toList()
      ..sort((a, b) => b['quantity'].compareTo(a['quantity']));

    return sortedItems.take(5).toList();
  }

  Future<List<Map<String, dynamic>>> _getBestSellersForChart(
      String period) async {
    final bestSellers = await _getBestSellersData(period);

    // Convert to chart format
    return bestSellers
        .map((item) => {
              'name': item['name'],
              'quantity': item['quantity'],
              'total': item['total'],
            })
        .toList();
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
              primary: AppTheme.primaryColor,
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
        backgroundColor: AppTheme.primaryColor,
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
            const SizedBox(width: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  TextWidget(
                    text: _currentBranch ?? 'No Branch',
                    fontSize: 14,
                    fontFamily: 'Medium',
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: _selectedPeriod,
                dropdownColor: AppTheme.primaryColor,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Charts Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily/Monthly Income Chart
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextWidget(
                                text: 'Income Trends',
                                fontSize: 18,
                                fontFamily: 'Bold',
                                color: AppTheme.primaryColor,
                                isBold: true,
                              ),
                              DropdownButton<String>(
                                value: _selectedPeriod == 'Daily' ||
                                        _selectedPeriod == 'Weekly'
                                    ? 'Daily'
                                    : 'Monthly',
                                items: ['Daily', 'Monthly'].map((period) {
                                  return DropdownMenuItem(
                                    value: period,
                                    child: TextWidget(
                                      text: period,
                                      fontSize: 14,
                                      fontFamily: 'Regular',
                                      color: AppTheme.primaryColor,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 250,
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: _selectedPeriod == 'Daily' ||
                                      _selectedPeriod == 'Weekly'
                                  ? _getDailyIncomeData()
                                  : _getMonthlyIncomeData(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                    child: TextWidget(
                                      text: 'Error: ${snapshot.error}',
                                      fontSize: 14,
                                      fontFamily: 'Regular',
                                      color: festiveRed,
                                    ),
                                  );
                                }
                                final data = snapshot.data ?? [];
                                if (data.isEmpty) {
                                  return Center(
                                    child: TextWidget(
                                      text: 'No data available',
                                      fontSize: 14,
                                      fontFamily: 'Regular',
                                      color: Colors.grey,
                                    ),
                                  );
                                }
                                return LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.withOpacity(0.3),
                                          strokeWidth: 1,
                                        );
                                      },
                                      getDrawingVerticalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.withOpacity(0.3),
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() >= 0 &&
                                                value.toInt() < data.length) {
                                              return SideTitleWidget(
                                                axisSide: meta.axisSide,
                                                child: TextWidget(
                                                  text: data[value.toInt()]
                                                      ['date'],
                                                  fontSize: 10,
                                                  fontFamily: 'Regular',
                                                  color: Colors.grey[600],
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 42,
                                          getTitlesWidget: (value, meta) {
                                            return TextWidget(
                                              text: 'P${value.toInt()}',
                                              fontSize: 10,
                                              fontFamily: 'Regular',
                                              color: Colors.grey[600],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(
                                          color: Colors.grey.withOpacity(0.3)),
                                    ),
                                    minX: 0,
                                    maxX: (data.length - 1).toDouble(),
                                    minY: 0,
                                    maxY: data.isNotEmpty
                                        ? data
                                                .map((item) =>
                                                    item['income'] as double)
                                                .reduce(
                                                    (a, b) => a > b ? a : b) *
                                            1.2
                                        : 100,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots:
                                            data.asMap().entries.map((entry) {
                                          return FlSpot(entry.key.toDouble(),
                                              entry.value['income'] as double);
                                        }).toList(),
                                        isCurved: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.primaryColor
                                                .withOpacity(0.8),
                                            AppTheme.primaryColor,
                                          ],
                                        ),
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter:
                                              (spot, percent, barData, index) {
                                            return FlDotCirclePainter(
                                              radius: 4,
                                              color: AppTheme.primaryColor,
                                              strokeWidth: 2,
                                              strokeColor: Colors.white,
                                            );
                                          },
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              AppTheme.primaryColor
                                                  .withOpacity(0.3),
                                              AppTheme.primaryColor
                                                  .withOpacity(0.1),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Order Types Chart
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
                            text: 'Order Types',
                            fontSize: 18,
                            fontFamily: 'Bold',
                            color: AppTheme.primaryColor,
                            isBold: true,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 250,
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: _getOrderTypeData(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                    child: TextWidget(
                                      text: 'Error: ${snapshot.error}',
                                      fontSize: 14,
                                      fontFamily: 'Regular',
                                      color: festiveRed,
                                    ),
                                  );
                                }
                                final data = snapshot.data ?? [];
                                if (data.isEmpty ||
                                    data.every((item) => item['count'] == 0)) {
                                  return Center(
                                    child: TextWidget(
                                      text: 'No order data available',
                                      fontSize: 14,
                                      fontFamily: 'Regular',
                                      color: Colors.grey,
                                    ),
                                  );
                                }
                                return PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 60,
                                    sections: data.map((item) {
                                      final color = item['type'] == 'Dine in'
                                          ? Colors.orange
                                          : Colors.purple;
                                      final count = item['count'] as int;
                                      final total = data.fold(
                                          0,
                                          (sum, item) =>
                                              sum + (item['count'] as int));
                                      final percentage = total > 0
                                          ? (count / total * 100)
                                          : 0.0;

                                      return PieChartSectionData(
                                        color: color,
                                        value: count.toDouble(),
                                        title:
                                            '${percentage.toStringAsFixed(1)}%',
                                        radius: 50,
                                        titleStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        badgeWidget: count > 0
                                            ? _badge(
                                                item['type'],
                                                count,
                                                color,
                                              )
                                            : null,
                                        badgePositionPercentageOffset: .98,
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem('Dine in', Colors.orange),
                              const SizedBox(width: 20),
                              _buildLegendItem('Pickup', Colors.purple),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Original Content
            Row(
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
                            color: AppTheme.primaryColor,
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
                          const SizedBox(height: 12),
                          FutureBuilder<Map<String, dynamic>>(
                            future: _calculatePaymentBreakdown(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
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
                              final breakdown = snapshot.data ??
                                  {
                                    'paymentMethods': {
                                      'Cash': 0.0,
                                      'GCash': 0.0
                                    },
                                    'orderTypes': {'Dine in': 0, 'Pickup': 0}
                                  };
                              final paymentMethods = breakdown['paymentMethods']
                                  as Map<String, dynamic>;
                              final orderTypes = breakdown['orderTypes']
                                  as Map<String, dynamic>;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: 'Payment Breakdown',
                                    fontSize: 18,
                                    fontFamily: 'Bold',
                                    color: AppTheme.primaryColor,
                                    isBold: true,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildBreakdownCard(
                                          title: 'Cash',
                                          amount:
                                              paymentMethods['Cash'] as double,
                                          icon: Icons.money,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildBreakdownCard(
                                          title: 'GCash',
                                          amount:
                                              paymentMethods['GCash'] as double,
                                          icon: Icons.phone_android,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextWidget(
                                    text: 'Order Type Summary',
                                    fontSize: 18,
                                    fontFamily: 'Bold',
                                    color: AppTheme.primaryColor,
                                    isBold: true,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildOrderTypeCard(
                                          title: 'Dine in',
                                          count: orderTypes['Dine in'] as int,
                                          icon: Icons.restaurant,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildOrderTypeCard(
                                          title: 'Pickup',
                                          count: orderTypes['Pickup'] as int,
                                          icon: Icons.takeout_dining,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
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
                            color: AppTheme.primaryColor,
                            isBold: true,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 400,
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
                                return FutureBuilder<
                                    List<Map<String, dynamic>>>(
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
                                          text:
                                              'Error: ${reportSnapshot.error}',
                                          fontSize: 16,
                                          fontFamily: 'Regular',
                                          color: festiveRed,
                                        ),
                                      );
                                    }
                                    final salesReport =
                                        reportSnapshot.data ?? [];
                                    if (salesReport.isEmpty) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.receipt_long,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            SizedBox(height: 16),
                                            TextWidget(
                                              text: 'No sales data found',
                                              fontSize: 18,
                                              fontFamily: 'Medium',
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(height: 8),
                                            TextWidget(
                                              text:
                                                  'Try adjusting the date range',
                                              fontSize: 14,
                                              fontFamily: 'Regular',
                                              color: Colors.grey[500],
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return SingleChildScrollView(
                                      child: DataTable(
                                        columnSpacing: 16,
                                        dataRowHeight: 60,
                                        headingRowColor: WidgetStatePropertyAll(
                                            AppTheme.primaryColor
                                                .withOpacity(0.1)),
                                        columns: [
                                          DataColumn(
                                            label: TextWidget(
                                              text: 'Date',
                                              fontSize: 16,
                                              fontFamily: 'Bold',
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          DataColumn(
                                            label: TextWidget(
                                              text: 'Total Sales (P)',
                                              fontSize: 16,
                                              fontFamily: 'Bold',
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          DataColumn(
                                            label: TextWidget(
                                              text: 'Transactions',
                                              fontSize: 16,
                                              fontFamily: 'Bold',
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          DataColumn(
                                            label: TextWidget(
                                              text: 'Avg. Transaction (P)',
                                              fontSize: 16,
                                              fontFamily: 'Bold',
                                              color: AppTheme.primaryColor,
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
            const SizedBox(height: 20),
            // Best Sellers Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextWidget(
                          text: 'Top 5 Best Sellers',
                          fontSize: 18,
                          fontFamily: 'Bold',
                          color: AppTheme.primaryColor,
                          isBold: true,
                        ),
                        DropdownButton<String>(
                          value: _selectedPeriod == 'Custom'
                              ? 'Daily'
                              : _selectedPeriod,
                          items: ['Daily', 'Weekly', 'Monthly'].map((period) {
                            return DropdownMenuItem(
                              value: period,
                              child: TextWidget(
                                text: period,
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: AppTheme.primaryColor,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chart Section
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 300,
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: _getBestSellersForChart(
                                  _selectedPeriod == 'Custom'
                                      ? 'Daily'
                                      : _selectedPeriod),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                    child: TextWidget(
                                      text: 'Error: ${snapshot.error}',
                                      fontSize: 14,
                                      fontFamily: 'Regular',
                                      color: festiveRed,
                                    ),
                                  );
                                }
                                final data = snapshot.data ?? [];
                                if (data.isEmpty) {
                                  return Center(
                                    child: TextWidget(
                                      text: 'No sales data available',
                                      fontSize: 14,
                                      fontFamily: 'Regular',
                                      color: Colors.grey,
                                    ),
                                  );
                                }
                                return BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: data.isNotEmpty
                                        ? data
                                                .map((item) =>
                                                    item['quantity'] as int)
                                                .reduce(
                                                    (a, b) => a > b ? a : b) *
                                            1.2
                                        : 10,
                                    barTouchData: BarTouchData(
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (group) =>
                                            Colors.blueGrey,
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                          final item = data[group.x.toInt()];
                                          return BarTooltipItem(
                                            '${item['name']}\nQty: ${item['quantity']}\nRevenue: P${item['total'].toStringAsFixed(2)}',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 60,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() >= 0 &&
                                                value.toInt() < data.length) {
                                              final itemName =
                                                  data[value.toInt()]['name']
                                                      as String;
                                              // Truncate long item names
                                              final displayName = itemName
                                                          .length >
                                                      10
                                                  ? '${itemName.substring(0, 10)}...'
                                                  : itemName;
                                              return SideTitleWidget(
                                                axisSide: meta.axisSide,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8.0),
                                                  child: TextWidget(
                                                    text: displayName,
                                                    fontSize: 10,
                                                    fontFamily: 'Regular',
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) {
                                            return TextWidget(
                                              text: value.toInt().toString(),
                                              fontSize: 10,
                                              fontFamily: 'Regular',
                                              color: Colors.grey[600],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(
                                          color: Colors.grey.withOpacity(0.3)),
                                    ),
                                    barGroups:
                                        data.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: item['quantity'].toDouble(),
                                            color: _getBarColor(index),
                                            width: 22,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(4),
                                              topRight: Radius.circular(4),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Data Table Section
                        Expanded(
                          flex: 1,
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: _getBestSellersData(
                                _selectedPeriod == 'Custom'
                                    ? 'Daily'
                                    : _selectedPeriod),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: TextWidget(
                                    text: 'Error: ${snapshot.error}',
                                    fontSize: 14,
                                    fontFamily: 'Regular',
                                    color: festiveRed,
                                  ),
                                );
                              }
                              final data = snapshot.data ?? [];
                              if (data.isEmpty) {
                                return Center(
                                  child: TextWidget(
                                    text: 'No sales data available',
                                    fontSize: 14,
                                    fontFamily: 'Regular',
                                    color: Colors.grey,
                                  ),
                                );
                              }
                              return SingleChildScrollView(
                                child: DataTable(
                                  columnSpacing: 12,
                                  dataRowHeight: 50,
                                  headingRowColor: WidgetStatePropertyAll(
                                      AppTheme.primaryColor.withOpacity(0.1)),
                                  columns: [
                                    DataColumn(
                                      label: TextWidget(
                                        text: 'Rank',
                                        fontSize: 14,
                                        fontFamily: 'Bold',
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    DataColumn(
                                      label: TextWidget(
                                        text: 'Item Name',
                                        fontSize: 14,
                                        fontFamily: 'Bold',
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    DataColumn(
                                      label: TextWidget(
                                        text: 'Qty',
                                        fontSize: 14,
                                        fontFamily: 'Bold',
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    DataColumn(
                                      label: TextWidget(
                                        text: 'Revenue',
                                        fontSize: 14,
                                        fontFamily: 'Bold',
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                  rows: data.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    return DataRow(
                                      color: WidgetStatePropertyAll(
                                          index % 2 == 0
                                              ? Colors.transparent
                                              : Colors.grey.withOpacity(0.05)),
                                      cells: [
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: _getRankColor(index),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: TextWidget(
                                              text: '#${index + 1}',
                                              fontSize: 12,
                                              fontFamily: 'Bold',
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          TextWidget(
                                            text: item['name'],
                                            fontSize: 12,
                                            fontFamily: 'Regular',
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        DataCell(
                                          TextWidget(
                                            text: item['quantity'].toString(),
                                            fontSize: 12,
                                            fontFamily: 'Regular',
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        DataCell(
                                          TextWidget(
                                            text:
                                                'P${item['total'].toStringAsFixed(2)}',
                                            fontSize: 12,
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
                          ),
                        ),
                      ],
                    ),
                  ],
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
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
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
                  color: AppTheme.primaryColor,
                  isBold: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get bar colors for the chart
  Color _getBarColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Gold for 1st place
      case 1:
        return Colors.grey; // Silver for 2nd place
      case 2:
        return Colors.brown; // Bronze for 3rd place
      default:
        return AppTheme.primaryColor; // Primary color for others
    }
  }

  // Helper method to get rank colors for the data table
  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Gold for 1st place
      case 1:
        return Colors.grey; // Silver for 2nd place
      case 2:
        return Colors.brown; // Bronze for 3rd place
      default:
        return AppTheme.primaryColor; // Primary color for others
    }
  }

  Widget _buildBreakdownCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
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
              backgroundColor: color.withOpacity(0.1),
              child: Icon(
                icon,
                color: color,
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
                  color: color,
                  isBold: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
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
              backgroundColor: color.withOpacity(0.1),
              child: Icon(
                icon,
                color: color,
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
                  text: '$count orders',
                  fontSize: 20,
                  fontFamily: 'Bold',
                  color: color,
                  isBold: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for pie chart badges
  Widget _badge(String text, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextWidget(
        text: '$text ($count)',
        fontSize: 12,
        fontFamily: 'Medium',
        color: Colors.white,
      ),
    );
  }

  // Helper widget for chart legend items
  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        TextWidget(
          text: text,
          fontSize: 14,
          fontFamily: 'Regular',
          color: Colors.grey[700],
        ),
      ],
    );
  }
}
