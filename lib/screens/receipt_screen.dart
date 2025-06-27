import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  _ReceiptScreenState createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
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
  ];

  List<Map<String, dynamic>> _filteredReceipts() {
    List<Map<String, dynamic>> filtered = _receipts;
    if (_selectedDateRange != null) {
      filtered = filtered.where((receipt) {
        final receiptDate = receipt['date'] as DateTime;
        return receiptDate.isAfter(
                _selectedDateRange!.start.subtract(Duration(days: 1))) &&
            receiptDate
                .isBefore(_selectedDateRange!.end.add(Duration(days: 1)));
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((receipt) =>
              receipt['id']
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              receipt['customer']
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return filtered;
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
      });
    }
  }

  void _showReceiptDetails(BuildContext context, Map<String, dynamic> receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: TextWidget(
          text: 'Receipt Details - ${receipt['id']}',
          fontSize: 18,
          fontFamily: 'Bold',
          color: primaryBlue,
          isBold: true,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text:
                    'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(receipt['date'])}',
                fontSize: 14,
                fontFamily: 'Regular',
                color: Colors.grey[800],
              ),
              TextWidget(
                text: 'Customer: ${receipt['customer']}',
                fontSize: 14,
                fontFamily: 'Regular',
                color: Colors.grey[800],
              ),
              TextWidget(
                text: 'Payment Method: ${receipt['paymentMethod']}',
                fontSize: 14,
                fontFamily: 'Regular',
                color: Colors.grey[800],
              ),
              TextWidget(
                text: 'Total: P${receipt['total'].toStringAsFixed(2)}',
                fontSize: 14,
                fontFamily: 'Regular',
                color: Colors.grey[800],
              ),
              const SizedBox(height: 12),
              TextWidget(
                text: 'Items:',
                fontSize: 16,
                fontFamily: 'Medium',
                color: Colors.grey[800],
              ),
              ...receipt['items'].map<Widget>((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextWidget(
                      text:
                          '${item['name']} x${item['quantity']} - P${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.grey[600],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          ButtonWidget(
            radius: 8,
            color: primaryBlue,
            textColor: Colors.white,
            label: 'Close',
            onPressed: () => Navigator.pop(context),
            fontSize: 14,
          ),
        ],
      ),
    );
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
              text: 'Receipts',
              fontSize: 20,
              fontFamily: 'Bold',
              color: Colors.white,
              isBold: true,
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by ID or Customer',
                  hintStyle: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Regular',
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters and Summary
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: 'Filter Receipts',
                            fontSize: 16,
                            fontFamily: 'Bold',
                            color: primaryBlue,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextWidget(
                                  text: _selectedDateRange == null
                                      ? 'All Receipts'
                                      : 'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}',
                                  fontSize: 14,
                                  fontFamily: 'Regular',
                                  color: Colors.grey[800],
                                ),
                              ),
                              ButtonWidget(
                                radius: 8,
                                color: primaryBlue,
                                textColor: Colors.white,
                                label: 'Select Date Range',
                                onPressed: () => _selectDateRange(context),
                                fontSize: 12,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextWidget(
                          text: 'Total Receipts: ${_filteredReceipts().length}',
                          fontSize: 14,
                          fontFamily: 'Medium',
                          color: Colors.grey[800],
                        ),
                        TextWidget(
                          text:
                              'Total Amount: P${_filteredReceipts().fold(0.0, (sum, receipt) => sum + receipt['total']).toStringAsFixed(2)}',
                          fontSize: 14,
                          fontFamily: 'Medium',
                          color: Colors.grey[800],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Receipts Table
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 16,
                    dataRowHeight: 60,
                    headingRowColor:
                        WidgetStatePropertyAll(primaryBlue.withOpacity(0.1)),
                    columns: [
                      DataColumn(
                        label: TextWidget(
                          text: 'Receipt ID',
                          fontSize: 16,
                          fontFamily: 'Bold',
                          color: primaryBlue,
                        ),
                      ),
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
                          text: 'Customer',
                          fontSize: 16,
                          fontFamily: 'Bold',
                          color: primaryBlue,
                        ),
                      ),
                      DataColumn(
                        label: TextWidget(
                          text: 'Payment',
                          fontSize: 16,
                          fontFamily: 'Bold',
                          color: primaryBlue,
                        ),
                      ),
                      DataColumn(
                        label: TextWidget(
                          text: 'Total (P)',
                          fontSize: 16,
                          fontFamily: 'Bold',
                          color: primaryBlue,
                        ),
                      ),
                      DataColumn(
                        label: TextWidget(
                          text: 'Actions',
                          fontSize: 16,
                          fontFamily: 'Bold',
                          color: primaryBlue,
                        ),
                      ),
                    ],
                    rows: _filteredReceipts().map((receipt) {
                      return DataRow(
                        cells: [
                          DataCell(
                            TextWidget(
                              text: receipt['id'],
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: Colors.grey[800],
                            ),
                          ),
                          DataCell(
                            TextWidget(
                              text: DateFormat('MMM dd, yyyy HH:mm')
                                  .format(receipt['date']),
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: Colors.grey[800],
                            ),
                          ),
                          DataCell(
                            TextWidget(
                              text: receipt['customer'],
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: Colors.grey[800],
                            ),
                          ),
                          DataCell(
                            TextWidget(
                              text: receipt['paymentMethod'],
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: Colors.grey[800],
                            ),
                          ),
                          DataCell(
                            TextWidget(
                              text: receipt['total'].toStringAsFixed(2),
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: Colors.grey[800],
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ButtonWidget(
                                  radius: 8,
                                  color: primaryBlue,
                                  textColor: Colors.white,
                                  label: 'Details',
                                  onPressed: () =>
                                      _showReceiptDetails(context, receipt),
                                  fontSize: 12,
                                ),
                                const SizedBox(width: 8),
                                ButtonWidget(
                                  radius: 8,
                                  color: Colors.grey[200]!,
                                  textColor: primaryBlue,
                                  label: 'Print',
                                  onPressed: () {
                                    // Placeholder for print functionality
                                  },
                                  fontSize: 12,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
