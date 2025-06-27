import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  _SalesReportScreenState createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  String _selectedPeriod = 'Daily';
  DateTimeRange? _selectedDateRange;
  final List<Map<String, dynamic>> _receipts = [
    {
      'id': 'REC001',
      'date': DateTime(2025, 6, 27, 8, 0),
      'total': 250.50,
      'customer': 'John Doe',
      'paymentMethod': 'Cash',
      'items': [
        {'name': 'Espresso', 'quantity': 2, 'price': 120.0},
        {'name': 'Croissant', 'quantity': 1, 'price': 80.0},
      ],
    },
    {
      'id': 'REC002',
      'date': DateTime(2025, 6, 26, 14, 30),
      'total': 350.75,
      'customer': 'Jane Smith',
      'paymentMethod': 'Card',
      'items': [
        {'name': 'Latte', 'quantity': 1, 'price': 150.0},
        {'name': 'Sandwich', 'quantity': 1, 'price': 200.0},
      ],
    },
    {
      'id': 'REC003',
      'date': DateTime(2025, 6, 25, 10, 15),
      'total': 100.0,
      'customer': 'Alex Brown',
      'paymentMethod': 'Mobile Payment',
      'items': [
        {'name': 'Iced Tea', 'quantity': 1, 'price': 100.0},
      ],
    },
    {
      'id': 'REC004',
      'date': DateTime(2025, 6, 24, 12, 45),
      'total': 180.25,
      'customer': 'Emily Davis',
      'paymentMethod': 'Cash',
      'items': [
        {'name': 'Cappuccino', 'quantity': 1, 'price': 130.0},
        {'name': 'Muffin', 'quantity': 1, 'price': 50.0},
      ],
    },
    {
      'id': 'REC005',
      'date': DateTime(2025, 6, 20, 9, 30),
      'total': 200.0,
      'customer': 'Michael Lee',
      'paymentMethod': 'Card',
      'items': [
        {'name': 'Latte', 'quantity': 1, 'price': 150.0},
        {'name': 'Muffin', 'quantity': 1, 'price': 50.0},
      ],
    },
  ];

  List<Map<String, dynamic>> _filteredReceipts() {
    final now = DateTime.now();
    if (_selectedDateRange != null) {
      return _receipts.where((receipt) {
        final receiptDate = receipt['date'] as DateTime;
        return receiptDate.isAfter(
                _selectedDateRange!.start.subtract(Duration(days: 1))) &&
            receiptDate
                .isBefore(_selectedDateRange!.end.add(Duration(days: 1)));
      }).toList();
    }
    switch (_selectedPeriod) {
      case 'Daily':
        return _receipts.where((receipt) {
          final receiptDate = receipt['date'] as DateTime;
          return receiptDate.year == now.year &&
              receiptDate.month == now.month &&
              receiptDate.day == now.day;
        }).toList();
      case 'Weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return _receipts.where((receipt) {
          final receiptDate = receipt['date'] as DateTime;
          return receiptDate.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
              receiptDate.isBefore(startOfWeek.add(Duration(days: 7)));
        }).toList();
      case 'Monthly':
        return _receipts.where((receipt) {
          final receiptDate = receipt['date'] as DateTime;
          return receiptDate.year == now.year && receiptDate.month == now.month;
        }).toList();
      default:
        return _receipts;
    }
  }

  Map<String, double> _calculateIncome() {
    final filteredReceipts = _filteredReceipts();
    double dailyIncome = 0.0;
    double weeklyIncome = 0.0;
    double monthlyIncome = 0.0;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (var receipt in _receipts) {
      final receiptDate = receipt['date'] as DateTime;
      final total = receipt['total'] as double;
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

  List<Map<String, dynamic>> _generateSalesReport() {
    final filteredReceipts = _filteredReceipts();
    final now = DateTime.now();
    final report = <Map<String, dynamic>>[];

    if (_selectedPeriod == 'Daily' || _selectedDateRange != null) {
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (var receipt in filteredReceipts) {
        final date = receipt['date'] as DateTime;
        final dateKey = DateFormat('MMM dd, yyyy').format(date);
        grouped[dateKey] = grouped[dateKey] ?? [];
        grouped[dateKey]!.add(receipt);
      }
      grouped.forEach((date, receipts) {
        final totalSales = receipts.fold(0.0, (sum, r) => sum + r['total']);
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
        final receiptsInWeek = filteredReceipts.where((r) {
          final date = r['date'] as DateTime;
          return date.isAfter(weekStart.subtract(Duration(days: 1))) &&
              date.isBefore(weekEnd.add(Duration(days: 1)));
        }).toList();
        if (receiptsInWeek.isNotEmpty) {
          final totalSales =
              receiptsInWeek.fold(0.0, (sum, r) => sum + r['total']);
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
        final receiptsInMonth = filteredReceipts.where((r) {
          final date = r['date'] as DateTime;
          return date.year == month.year && date.month == month.month;
        }).toList();
        if (receiptsInMonth.isNotEmpty) {
          final totalSales =
              receiptsInMonth.fold(0.0, (sum, r) => sum + r['total']);
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
      lastDate: DateTime(2026),
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

  @override
  Widget build(BuildContext context) {
    final income = _calculateIncome();
    final salesReport = _generateSalesReport();

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
                items: ['Daily', 'Weekly', 'Monthly'].map((period) {
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
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income Summary
            Expanded(
              flex: 1,
              child: Column(
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
              ),
            ),
            const SizedBox(width: 16),
            // Sales Report Table
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
                        child: SingleChildScrollView(
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
                                      text: report['transactions'].toString(),
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
