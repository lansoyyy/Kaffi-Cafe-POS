import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/utils/branch_service.dart';
import 'package:kaffi_cafe_pos/utils/role_service.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';

// Added: Import for date picker widget
import 'package:kaffi_cafe_pos/widgets/date_picker_widget.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  DateTime? _selectedDay;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentBranch;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _getCurrentBranch();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearchQuery(Map<String, dynamic> transactionData) {
    if (_searchQuery.isEmpty) return true;
    final orderId = transactionData['orderId']?.toString().toLowerCase() ?? '';
    return orderId.contains(_searchQuery.toLowerCase());
  }

  Future<void> _getCurrentBranch() async {
    final currentBranch = await BranchService.getSelectedBranch();
    if (mounted) {
      setState(() {
        _currentBranch = currentBranch;
      });
    }
  }

  // Method to get current staff name
  Future<String> _getCurrentStaffName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final staffName = prefs.getString('staffName') ?? '';
      return staffName;
    } catch (e) {
      return '';
    }
  }

  // Modified: Changed from delete to print receipt
  Future<void> _printReceipt(String orderId, String itemName,
      Map<String, dynamic> transactionData) async {
    final pdf = pw.Document();
    try {
      final data = transactionData;
      final items = data['items'] as List<dynamic>;

      // Get current staff name
      final staffName = await _getCurrentStaffName();
      final isAdmin = await RoleService.isSuperAdmin();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('KAFFI CAFE',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text(_currentBranch ?? '',
                    style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 10),
                pw.Text('RECEIPT',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Order ID:'),
                    pw.Text(data['orderId'] ?? ''),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date:'),
                    pw.Text(DateFormat('MMM dd, yyyy HH:mm')
                        .format(data['timestamp'].toDate())),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Customer:'),
                    pw.Text(data['buyer'] ?? 'N/A'),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Table(
                  border: pw.TableBorder.symmetric(),
                  columnWidths: {
                    0: const pw.FractionColumnWidth(0.6),
                    1: const pw.FractionColumnWidth(0.2),
                    2: const pw.FractionColumnWidth(0.2),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text('Item',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Qty',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center),
                        pw.Text('Price',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ],
                    ),
                    ...items.map((item) => pw.TableRow(
                          children: [
                            pw.Text(item['name']),
                            pw.Text(item['quantity'].toString(),
                                textAlign: pw.TextAlign.center),
                            pw.Text(
                                'P${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                textAlign: pw.TextAlign.right),
                          ],
                        )),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL:',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('P${data['total'].toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),

                // Only show staff name if not admin
                if (!isAdmin && staffName.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  pw.Text('Served by: $staffName',
                      style: const pw.TextStyle(fontSize: 10)),
                ],

                pw.SizedBox(height: 20),
                pw.Text('Thank you for your purchase!',
                    style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 5),
                pw.Text('Please come again!',
                    style: const pw.TextStyle(fontSize: 12)),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Receipt printed successfully',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error printing receipt: $e',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: festiveRed,
        ),
      );
    }
  }

  // Added: Method to show transaction details
  void _showTransactionDetails(Map<String, dynamic> transactionData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextWidget(
                        text: 'Transaction Details',
                        fontSize: 20,
                        fontFamily: 'Bold',
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow('Order ID', transactionData['orderId']),
                    _buildDetailRow(
                        'Customer', transactionData['buyer'] ?? 'N/A'),
                    _buildDetailRow(
                        'Date',
                        DateFormat('MMM dd, yyyy HH:mm')
                            .format(transactionData['timestamp'].toDate())),
                    const SizedBox(height: 20),
                    TextWidget(
                      text: 'Items',
                      fontSize: 18,
                      fontFamily: 'Bold',
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 10),
                    ...transactionData['items'].map<Widget>((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: TextWidget(
                                text: item['name'],
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.grey[800],
                              ),
                            ),
                            TextWidget(
                              text: 'x${item['quantity']}',
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: Colors.grey[800],
                            ),
                            TextWidget(
                              text:
                                  'P${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: Colors.grey[800],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextWidget(
                          text: 'Total Amount:',
                          fontSize: 16,
                          fontFamily: 'Bold',
                          color: AppTheme.primaryColor,
                        ),
                        TextWidget(
                          text:
                              'P${transactionData['total'].toStringAsFixed(2)}',
                          fontSize: 16,
                          fontFamily: 'Bold',
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ButtonWidget(
                        width: 200,
                        radius: 8,
                        color: AppTheme.primaryColor,
                        textColor: Colors.white,
                        label: 'Print Receipt',
                        onPressed: () {
                          Navigator.pop(context);
                          _printReceipt(
                              transactionData['orderId'],
                              transactionData['items'][0]['name'],
                              transactionData);
                        },
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Added: Helper method to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: TextWidget(
              text: '$label:',
              fontSize: 14,
              fontFamily: 'Bold',
              color: AppTheme.primaryColor,
            ),
          ),
          Expanded(
            flex: 2,
            child: TextWidget(
              text: value,
              fontSize: 14,
              fontFamily: 'Regular',
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  // Added: Method to show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await datePickerWidget(context, _selectedDay!);
    if (picked != null && picked != _selectedDay) {
      setState(() {
        _selectedDay = picked;
      });
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('branch', isEqualTo: _currentBranch)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                  _selectedDay!.year, _selectedDay!.month, _selectedDay!.day)))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(DateTime(
                  _selectedDay!.year,
                  _selectedDay!.month,
                  _selectedDay!.day + 1)))
          .orderBy('timestamp', descending: true)
          .get();

      final now = DateTime.now();
      final String reportDate =
          DateFormat('MMMM dd, yyyy').format(_selectedDay!);
      final String reportTime = DateFormat('hh:mm a').format(now);

      // Calculate totals
      int totalTransactions = snapshot.docs.length;
      double totalAmount = 0.0;
      int totalItems = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Fixed: Use 'total' instead of 'totalAmount' for consistency
        totalAmount += data['total'] ?? 0.0;
        final items = data['items'] as List<dynamic>;
        totalItems += items.length;
      }

      List<List<dynamic>> csvData = [
        // Header section
        ['KAFFI CAFE TRANSACTION REPORT'],
        ['Branch: ${_currentBranch ?? 'Unknown'}'],
        ['Report Date: $reportDate'],
        [
          'Generated on: ${DateFormat('MMMM dd, yyyy').format(now)} at $reportTime'
        ],
        ['Prepared by: Administrator'],
        [],
        // Summary section
        ['TRANSACTION SUMMARY'],
        ['Total Transactions', totalTransactions],
        ['Total Items Sold', totalItems],
        ['Total Revenue', 'P${totalAmount.toStringAsFixed(2)}'],
        [],
        // Transactions detail header
        ['TRANSACTION DETAILS'],
        [
          'Order ID',
          'Item',
          'Quantity',
          'Price',
          'Subtotal',
          'Date',
          'Customer',
          'Payment Method'
        ],
      ];

      // Add transaction details
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;
        final orderDate =
            DateFormat('MMM dd, yyyy HH:mm').format(data['timestamp'].toDate());
        final customer = data['buyer'] ?? 'N/A';
        final paymentMethod = data['paymentMethod'] ?? 'N/A';

        for (var item in items) {
          final subtotal =
              (item['price'] as double) * (item['quantity'] as int);
          csvData.add([
            data['orderId'] ?? '',
            item['name'] ?? '',
            item['quantity'] ?? 0,
            'P${(item['price'] as double).toStringAsFixed(2)}',
            'P${subtotal.toStringAsFixed(2)}',
            orderDate,
            customer,
            paymentMethod,
          ]);
        }
      }

      // Footer section
      csvData.addAll([
        [],
        ['REPORT FOOTER'],
        ['End of Report'],
        ['This is a system-generated report'],
        ['For inquiries, contact the cafe management'],
        [],
        ['Page 1 of 1'],
      ]);

      final csvString = const ListToCsvConverter().convert(csvData);
      final fileName =
          'kaffi_cafe_transactions_${DateFormat('yyyyMMdd').format(_selectedDay!)}.csv';

      String? savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: utf8.encode(csvString),
        ext: 'csv',
        mimeType: MimeType.csv,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: savedPath != null
                ? 'Transaction report saved to: $savedPath'
                : 'Transaction report exported to CSV successfully',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 5),
        ),
      );
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

  Future<void> _printTransactionSummary() async {
    final pdf = pw.Document();
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('branch', isEqualTo: _currentBranch)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                  _selectedDay!.year, _selectedDay!.month, _selectedDay!.day)))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(DateTime(
                  _selectedDay!.year,
                  _selectedDay!.month,
                  _selectedDay!.day + 1)))
          .orderBy('timestamp', descending: true)
          .get();

      final now = DateTime.now();
      final String reportDate =
          DateFormat('MMMM dd, yyyy').format(_selectedDay!);
      final String reportTime = DateFormat('hh:mm a').format(now);
      final String generatedDate = DateFormat('MMMM dd, yyyy').format(now);

      // Calculate totals
      int totalTransactions = snapshot.docs.length;
      double totalAmount = 0.0;
      int totalItems = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Fixed: Use 'total' instead of 'totalAmount' for consistency
        totalAmount += data['total'] ?? 0.0;
        final items = data['items'] as List<dynamic>;
        totalItems += items.length;
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('KAFFI CAFE',
                          style: pw.TextStyle(
                              fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text(_currentBranch ?? 'Unknown Branch',
                          style: const pw.TextStyle(fontSize: 14)),
                      pw.SizedBox(height: 5),
                      pw.Text('TRANSACTION REPORT',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text('Date: $reportDate',
                          style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('Generated: $generatedDate at $reportTime',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 10),
                      pw.Divider(thickness: 1),
                    ],
                  ),
                ),

                // Summary Section
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SUMMARY',
                          style: pw.TextStyle(
                              fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Transactions:'),
                          pw.Text(totalTransactions.toString(),
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Items Sold:'),
                          pw.Text(totalItems.toString(),
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Revenue:'),
                          pw.Text('P${totalAmount.toStringAsFixed(2)}',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Transaction Details
                pw.SizedBox(height: 20),
                pw.Text('TRANSACTION DETAILS',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),

                pw.Expanded(
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      0: const pw.FractionColumnWidth(0.15), // Order ID
                      1: const pw.FractionColumnWidth(0.25), // Customer
                      2: const pw.FractionColumnWidth(0.25), // Items
                      3: const pw.FractionColumnWidth(0.15), // Time
                      4: const pw.FractionColumnWidth(0.2), // Total
                    },
                    children: [
                      // Table Header
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Order ID',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10)),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Customer',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10)),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Items',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10)),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Time',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10)),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Total',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10)),
                          ),
                        ],
                      ),
                      // Table Rows
                      ...snapshot.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final items = data['items'] as List<dynamic>;
                        final itemsText = items
                                .map((item) =>
                                    '${item['name']}(${item['quantity']})')
                                .take(2)
                                .join(', ') +
                            (items.length > 2 ? '...' : '');

                        return pw.TableRow(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(data['orderId'] ?? '',
                                  style: const pw.TextStyle(fontSize: 9)),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(data['buyer'] ?? 'N/A',
                                  style: const pw.TextStyle(fontSize: 9)),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(itemsText,
                                  style: const pw.TextStyle(fontSize: 9)),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                  DateFormat('HH:mm')
                                      .format(data['timestamp'].toDate()),
                                  style: const pw.TextStyle(fontSize: 9)),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                  'P${(data['total'] ?? 0.0).toStringAsFixed(2)}',
                                  style: const pw.TextStyle(fontSize: 9)),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),

                // Footer
                pw.SizedBox(height: 20),
                pw.Container(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Divider(thickness: 1),
                      pw.SizedBox(height: 10),
                      pw.Text('Prepared by: Administrator',
                          style: pw.TextStyle(
                              fontSize: 10, fontStyle: pw.FontStyle.italic)),
                      pw.SizedBox(height: 5),
                      pw.Text('This is a system-generated report',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 5),
                      pw.Text('Page 1 of 1',
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Transaction report generated successfully',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error generating report: $e',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: festiveRed,
        ),
      );
    }
  }

  // New method for monthly backup
  Future<void> _printMonthlyTransactions() async {
    final pdf = pw.Document();
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('branch', isEqualTo: _currentBranch)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('timestamp', descending: true)
          .get();

      final String reportMonth = DateFormat('MMMM yyyy').format(now);
      final String reportTime = DateFormat('hh:mm a').format(now);
      final String generatedDate = DateFormat('MMMM dd, yyyy').format(now);

      // Calculate totals
      int totalTransactions = snapshot.docs.length;
      double totalAmount = 0.0;
      int totalItems = 0;

      // Group transactions by day
      Map<String, List<Map<String, dynamic>>> dailyTransactions = {};
      List<Map<String, dynamic>> allTransactions = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Fixed: Use 'total' instead of 'totalAmount' for consistency
        totalAmount += data['total'] ?? 0.0;
        final items = data['items'] as List<dynamic>;
        totalItems += items.length;

        final day = DateFormat('MMM dd').format(data['timestamp'].toDate());
        if (!dailyTransactions.containsKey(day)) {
          dailyTransactions[day] = [];
        }
        dailyTransactions[day]!.add(data);
        allTransactions.add(data);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (pw.Context context) {
            return pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('KAFFI CAFE',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text(_currentBranch ?? 'Unknown Branch',
                      style: const pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(height: 5),
                  pw.Text('MONTHLY TRANSACTION REPORT',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text('Month: $reportMonth',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('Generated: $generatedDate at $reportTime',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 1),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              child: pw.Column(
                children: [
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Prepared by: Administrator',
                          style: pw.TextStyle(
                              fontSize: 10, fontStyle: pw.FontStyle.italic)),
                      pw.Text('System Generated',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(
                          'Page ${context.pageNumber} of ${context.pagesCount}',
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            return [
              // Summary Section
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MONTHLY SUMMARY',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Transactions:'),
                        pw.Text(totalTransactions.toString(),
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Items Sold:'),
                        pw.Text(totalItems.toString(),
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Revenue:'),
                        pw.Text('P${totalAmount.toStringAsFixed(2)}',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              // Daily Breakdown
              pw.SizedBox(height: 20),
              pw.Text('DAILY BREAKDOWN',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FractionColumnWidth(0.2), // Date
                  1: const pw.FractionColumnWidth(0.2), // Transactions
                  2: const pw.FractionColumnWidth(0.2), // Items
                  3: const pw.FractionColumnWidth(0.4), // Revenue
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Date',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Transactions',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Items',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Revenue',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  // Table Rows
                  ...dailyTransactions.entries.map((entry) {
                    final dayTransactions = entry.value;
                    int dayItems = 0;
                    double dayRevenue = 0.0;

                    for (var transaction in dayTransactions) {
                      final data = transaction as Map<String, dynamic>;
                      // Fixed: Use 'total' instead of 'totalAmount' for consistency
                      dayRevenue += data['total'] ?? 0.0;
                      final items = data['items'] as List<dynamic>;
                      dayItems += items.length;
                    }

                    return pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(entry.key,
                              style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(dayTransactions.length.toString(),
                              style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(dayItems.toString(),
                              style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('P${dayRevenue.toStringAsFixed(2)}',
                              style: const pw.TextStyle(fontSize: 10)),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              // Detailed Transactions Section
              pw.SizedBox(height: 20),
              pw.Text('DETAILED TRANSACTIONS',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FractionColumnWidth(0.15), // Order ID
                  1: const pw.FractionColumnWidth(0.25), // Customer
                  2: const pw.FractionColumnWidth(0.25), // Items
                  3: const pw.FractionColumnWidth(0.15), // Time
                  4: const pw.FractionColumnWidth(0.2), // Total
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Order ID',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Customer',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Items',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Time',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Total',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  // Table Rows - All transactions
                  ...allTransactions.map((data) {
                    final items = data['items'] as List<dynamic>;
                    final itemsText = items
                            .map((item) =>
                                '${item['name']}(${item['quantity']})')
                            .take(2)
                            .join(', ') +
                        (items.length > 2 ? '...' : '');

                    return pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(data['orderId'] ?? '',
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(data['buyer'] ?? 'N/A',
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(itemsText,
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                              DateFormat('HH:mm')
                                  .format(data['timestamp'].toDate()),
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                              'P${(data['total'] ?? 0.0).toStringAsFixed(2)}',
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Monthly transaction report generated successfully',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error generating monthly report: $e',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: festiveRed,
        ),
      );
    }
  }

  // New method for monthly CSV export
  Future<void> _exportMonthlyToCSV() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('branch', isEqualTo: _currentBranch)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('timestamp', descending: true)
          .get();

      final String reportMonth = DateFormat('MMMM yyyy').format(now);
      final String reportTime = DateFormat('hh:mm a').format(now);

      // Calculate totals
      int totalTransactions = snapshot.docs.length;
      double totalAmount = 0.0;
      int totalItems = 0;

      // Group transactions by day
      Map<String, List<Map<String, dynamic>>> dailyTransactions = {};
      List<Map<String, dynamic>> allTransactions = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Fixed: Use 'total' instead of 'totalAmount' for consistency
        totalAmount += data['total'] ?? 0.0;
        final items = data['items'] as List<dynamic>;
        totalItems += items.length;

        final day = DateFormat('MMM dd').format(data['timestamp'].toDate());
        if (!dailyTransactions.containsKey(day)) {
          dailyTransactions[day] = [];
        }
        dailyTransactions[day]!.add(data);
        allTransactions.add(data);
      }

      List<List<dynamic>> csvData = [
        // Header section
        ['KAFFI CAFE MONTHLY TRANSACTION REPORT'],
        ['Branch: ${_currentBranch ?? 'Unknown'}'],
        ['Report Month: $reportMonth'],
        [
          'Generated on: ${DateFormat('MMMM dd, yyyy').format(now)} at $reportTime'
        ],
        ['Prepared by: Administrator'],
        [],
        // Summary section
        ['MONTHLY SUMMARY'],
        ['Total Transactions', totalTransactions],
        ['Total Items Sold', totalItems],
        ['Total Revenue', 'P${totalAmount.toStringAsFixed(2)}'],
        [],
        // Daily breakdown header
        ['DAILY BREAKDOWN'],
        ['Date', 'Transactions', 'Items Sold', 'Revenue'],
      ];

      // Add daily breakdown
      for (var entry in dailyTransactions.entries) {
        final dayTransactions = entry.value;
        int dayItems = 0;
        double dayRevenue = 0.0;

        for (var transaction in dayTransactions) {
          final data = transaction as Map<String, dynamic>;
          // Fixed: Use 'total' instead of 'totalAmount' for consistency
          dayRevenue += data['total'] ?? 0.0;
          final items = data['items'] as List<dynamic>;
          dayItems += items.length;
        }

        csvData.add([
          entry.key,
          dayTransactions.length,
          dayItems,
          'P${dayRevenue.toStringAsFixed(2)}',
        ]);
      }

      // Add detailed transactions section
      csvData.addAll([
        [],
        ['DETAILED TRANSACTIONS'],
        [
          'Order ID',
          'Item',
          'Quantity',
          'Price',
          'Subtotal',
          'Date',
          'Customer',
          'Payment Method'
        ],
      ]);

      // Add all transaction details
      for (var data in allTransactions) {
        final items = data['items'] as List<dynamic>;
        final orderDate =
            DateFormat('MMM dd, yyyy HH:mm').format(data['timestamp'].toDate());
        final customer = data['buyer'] ?? 'N/A';
        final paymentMethod = data['paymentMethod'] ?? 'N/A';

        for (var item in items) {
          final subtotal =
              (item['price'] as double) * (item['quantity'] as int);
          csvData.add([
            data['orderId'] ?? '',
            item['name'] ?? '',
            item['quantity'] ?? 0,
            'P${(item['price'] as double).toStringAsFixed(2)}',
            'P${subtotal.toStringAsFixed(2)}',
            orderDate,
            customer,
            paymentMethod,
          ]);
        }
      }

      // Footer section
      csvData.addAll([
        [],
        ['REPORT FOOTER'],
        ['End of Monthly Report'],
        ['This is a system-generated report'],
        ['For inquiries, contact the cafe management'],
        [],
        ['Page 1 of 1'],
      ]);

      final csvString = const ListToCsvConverter().convert(csvData);
      final fileName =
          'kaffi_cafe_monthly_transactions_${DateFormat('yyyyMM').format(now)}.csv';

      String? savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: utf8.encode(csvString),
        ext: 'csv',
        mimeType: MimeType.csv,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: savedPath != null
                ? 'Monthly report saved to: $savedPath'
                : 'Monthly transaction report exported to CSV successfully',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error exporting monthly report to CSV: $e',
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
              text: 'Transactions',
              fontSize: 20,
              fontFamily: 'Bold',
              color: Colors.white,
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
          ],
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                color: Colors.white,
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: 'Select Date',
                        fontSize: 18,
                        fontFamily: 'Bold',
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ButtonWidget(
                          width: 200,
                          radius: 8,
                          color: AppTheme.primaryColor,
                          textColor: Colors.white,
                          label:
                              DateFormat('MMM dd, yyyy').format(_selectedDay!),
                          onPressed: () => _selectDate(context),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextWidget(
                        text: 'Transaction Summary',
                        fontSize: 16,
                        fontFamily: 'Bold',
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('orders')
                            .where('branch', isEqualTo: _currentBranch)
                            .where('timestamp',
                                isGreaterThanOrEqualTo: Timestamp.fromDate(
                                    DateTime(
                                        _selectedDay!.year,
                                        _selectedDay!.month,
                                        _selectedDay!.day)))
                            .where('timestamp',
                                isLessThanOrEqualTo: Timestamp.fromDate(
                                    DateTime(
                                        _selectedDay!.year,
                                        _selectedDay!.month,
                                        _selectedDay!.day + 1)))
                            .snapshots(),
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
                          final orders = snapshot.data!.docs;
                          int totalTransactions = orders.length;
                          double totalAmount = 0;
                          int totalItems = 0;

                          for (var order in orders) {
                            final data = order.data() as Map<String, dynamic>;
                            totalAmount += data['totalAmount'] ?? 0;
                            final items = data['items'] as List<dynamic>;
                            totalItems += items.length;
                          }

                          return Column(
                            children: [
                              _buildSummaryRow('Total Transactions',
                                  totalTransactions.toString()),
                              _buildSummaryRow(
                                  'Total Items', totalItems.toString()),
                              _buildSummaryRow('Total Amount',
                                  'P${totalAmount.toStringAsFixed(2)}'),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                color: Colors.white,
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ButtonWidget(
                                  width: 125,
                                  radius: 8,
                                  color: AppTheme.primaryColor,
                                  textColor: Colors.white,
                                  label: 'Print Summary',
                                  onPressed: _printTransactionSummary,
                                  fontSize: 12,
                                ),
                                const SizedBox(width: 8),
                                ButtonWidget(
                                  width: 125,
                                  radius: 8,
                                  color: AppTheme.primaryColor,
                                  textColor: Colors.white,
                                  label: 'Export CSV',
                                  onPressed: _exportToCSV,
                                  fontSize: 12,
                                ),
                                const SizedBox(width: 8),
                                ButtonWidget(
                                  width: 125,
                                  radius: 8,
                                  color: Colors.green,
                                  textColor: Colors.white,
                                  label: 'Monthly PDF',
                                  onPressed: _printMonthlyTransactions,
                                  fontSize: 12,
                                ),
                                const SizedBox(width: 8),
                                ButtonWidget(
                                  width: 125,
                                  radius: 8,
                                  color: Colors.green,
                                  textColor: Colors.white,
                                  label: 'Monthly CSV',
                                  onPressed: _exportMonthlyToCSV,
                                  fontSize: 12,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          TextWidget(
                            text:
                                'Transactions for ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
                            fontSize: 18,
                            fontFamily: 'Bold',
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search by Order ID...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontFamily: 'Regular',
                                  fontSize: 14,
                                ),
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.grey[500]),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear,
                                            color: Colors.grey[500]),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontFamily: 'Regular',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(15.0),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('orders')
                                .where('branch', isEqualTo: _currentBranch)
                                .where('timestamp',
                                    isGreaterThanOrEqualTo: Timestamp.fromDate(
                                        DateTime(
                                            _selectedDay!.year,
                                            _selectedDay!.month,
                                            _selectedDay!.day)))
                                .where('timestamp',
                                    isLessThanOrEqualTo: Timestamp.fromDate(
                                        DateTime(
                                            _selectedDay!.year,
                                            _selectedDay!.month,
                                            _selectedDay!.day + 1)))
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
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
                              final orders = snapshot.data!.docs;
                              Map<String, List<Map<String, dynamic>>>
                                  categorizedItems = {
                                'Coffee': [],
                                'Drinks': [],
                                'Foods': [],
                              };

                              for (var order in orders) {
                                final data =
                                    order.data() as Map<String, dynamic>;
                                // Apply search filter
                                if (_matchesSearchQuery(data)) {
                                  final items = data['items'] as List<dynamic>;
                                  for (var item in items) {
                                    final category =
                                        item['category'] ?? 'Foods';
                                    categorizedItems[category]!.add({
                                      'name': item['name'],
                                      'quantity': item['quantity'],
                                      'price': item['price'],
                                      'orderId': order.id,
                                      'category': category,
                                      // Added: Include full transaction data for details
                                      'transactionData': data,
                                    });
                                  }
                                }
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: categorizedItems.entries.map((entry) {
                                  final items = entry.value;
                                  if (items.isEmpty) return const SizedBox();
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Table(
                                        border: TableBorder.all(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        columnWidths: const {
                                          0: FlexColumnWidth(2), // Order ID
                                          1: FlexColumnWidth(3), // Item
                                          2: FlexColumnWidth(2), // Qty
                                          3: FlexColumnWidth(2), // Price
                                          4: FixedColumnWidth(60), // Actions
                                        },
                                        children: [
                                          _buildTableHeader(),
                                          // Modified: Make table rows clickable
                                          ...items.map(
                                              (item) => _buildClickableTableRow(
                                                    item['name'],
                                                    item['quantity'],
                                                    item['price'],
                                                    item['orderId'],
                                                    item[
                                                        'transactionData'], // Added: Pass transaction data
                                                  )),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Added: Helper method to build summary rows
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextWidget(
            text: label,
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.grey[700],
          ),
          TextWidget(
            text: value,
            fontSize: 14,
            fontFamily: 'Bold',
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: 'Order ID',
            fontSize: 16,
            fontFamily: 'Bold',
            color: AppTheme.primaryColor,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: 'Item',
            fontSize: 16,
            fontFamily: 'Bold',
            color: AppTheme.primaryColor,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: 'Qty',
            fontSize: 16,
            fontFamily: 'Bold',
            color: AppTheme.primaryColor,
            align: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: 'Price',
            fontSize: 16,
            fontFamily: 'Bold',
            color: AppTheme.primaryColor,
            align: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: '',
            fontSize: 16,
            fontFamily: 'Bold',
            color: AppTheme.primaryColor,
            align: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // Modified: Make table rows clickable and pass transaction data
  TableRow _buildClickableTableRow(String item, int quantity, double price,
      String orderId, Map<String, dynamic> transactionData) {
    return TableRow(
      children: [
        // Added: Display order ID
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: transactionData['orderId'] ?? orderId,
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.grey[800],
          ),
        ),
        // Modified: Wrap item name in GestureDetector to make it clickable
        GestureDetector(
          onTap: () => _showTransactionDetails(transactionData),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextWidget(
              text: item,
              fontSize: 14,
              fontFamily: 'Regular',
              color: Colors.grey[800],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: quantity.toString(),
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.grey[800],
            align: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: 'P${(price * quantity).toStringAsFixed(2)}',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.grey[800],
            align: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: Icon(
              Icons.print,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            onPressed: () => _printReceipt(orderId, item, transactionData),
          ),
        ),
      ],
    );
  }
}
