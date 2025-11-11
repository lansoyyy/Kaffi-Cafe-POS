import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/utils/role_service.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  _ReceiptScreenState createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
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

  // Get current staff name
  Future<String> _getCurrentStaffName() async {
    final prefs = await SharedPreferences.getInstance();
    final staffName = prefs.getString('current_staff_name') ?? '';
    final isSuperAdmin = await RoleService.isSuperAdmin();

    // Return empty string if admin, otherwise return staff name
    if (isSuperAdmin) {
      return '';
    }
    return staffName;
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
          text: 'Receipt Details - ${receipt['orderId']}',
          fontSize: 18,
          fontFamily: 'Bold',
          color: AppTheme.primaryColor,
          isBold: true,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text:
                    'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(receipt['timestamp'].toDate())}',
                fontSize: 14,
                fontFamily: 'Regular',
                color: Colors.grey[800],
              ),
              TextWidget(
                text: 'Customer: ${receipt['buyer']}',
                fontSize: 14,
                fontFamily: 'Regular',
                color: Colors.grey[800],
              ),
              TextWidget(
                text:
                    'Payment Method: ${receipt['status'] == 'Accepted' ? 'Cash' : 'Unknown'}',
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
            color: AppTheme.primaryColor,
            textColor: Colors.white,
            label: 'Close',
            onPressed: () => Navigator.pop(context),
            fontSize: 14,
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(Map<String, dynamic> receipt) async {
    final pdf = pw.Document();

    // Get current staff name
    final staffName = await _getCurrentStaffName();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Kaffi Cafe',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('Receipt #${receipt['orderId']}',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.Text(
                  'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(receipt['timestamp'].toDate())}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Customer: ${receipt['buyer']}',
                  style: const pw.TextStyle(fontSize: 10)),
              // Only show staff name if not admin
              if (staffName.isNotEmpty) ...[
                pw.Text('Served by: $staffName',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
              pw.SizedBox(height: 10),
              pw.Text('Items:',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ...receipt['items'].map<pw.Widget>((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(
                      '${item['name']} x${item['quantity']} - P${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  )),
              pw.SizedBox(height: 10),
              pw.Text('Total: P${receipt['total'].toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    try {
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error printing receipt: $e',
            fontSize: 14,
            fontFamily: 'Medium',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
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
                  hintStyle: const TextStyle(
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
                            color: AppTheme.primaryColor,
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
                                color: AppTheme.primaryColor,
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
                    StreamBuilder<QuerySnapshot>(
                      stream: _selectedDateRange == null
                          ? _firestore
                              .collection('orders')
                              .orderBy('timestamp', descending: true)
                              .snapshots()
                          : _firestore
                              .collection('orders')
                              .where('timestamp',
                                  isGreaterThanOrEqualTo: Timestamp.fromDate(
                                      _selectedDateRange!.start))
                              .where('timestamp',
                                  isLessThanOrEqualTo: Timestamp.fromDate(
                                      _selectedDateRange!.end))
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }
                        final receipts = snapshot.data!.docs
                            .map((doc) => {
                                  ...doc.data() as Map<String, dynamic>,
                                  'docId': doc.id
                                })
                            .where((receipt) =>
                                receipt['orderId']
                                    .toString()
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()) ||
                                receipt['buyer']
                                    .toString()
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()))
                            .toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextWidget(
                              text: 'Total Receipts: ${receipts.length}',
                              fontSize: 14,
                              fontFamily: 'Medium',
                              color: Colors.grey[800],
                            ),
                            TextWidget(
                              text:
                                  'Total Amount: P${receipts.fold(0.0, (sum, receipt) => sum + (receipt['total'] as num)).toStringAsFixed(2)}',
                              fontSize: 14,
                              fontFamily: 'Medium',
                              color: Colors.grey[800],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: SingleChildScrollView(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _selectedDateRange == null
                        ? _firestore
                            .collection('orders')
                            .orderBy('timestamp', descending: true)
                            .snapshots()
                        : _firestore
                            .collection('orders')
                            .where('timestamp',
                                isGreaterThanOrEqualTo: Timestamp.fromDate(
                                    _selectedDateRange!.start))
                            .where('timestamp',
                                isLessThanOrEqualTo:
                                    Timestamp.fromDate(_selectedDateRange!.end))
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: TextWidget(
                            text: 'Error: ${snapshot.error}',
                            fontSize: 16,
                            fontFamily: 'Regular',
                            color: Colors.red[600],
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final receipts = snapshot.data!.docs
                          .map((doc) => {
                                ...doc.data() as Map<String, dynamic>,
                                'docId': doc.id
                              })
                          .where((receipt) =>
                              receipt['orderId']
                                  .toString()
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()) ||
                              receipt['buyer']
                                  .toString()
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()))
                          .toList();
                      return DataTable(
                        columnSpacing: 16,
                        dataRowHeight: 60,
                        headingRowColor: WidgetStatePropertyAll(
                            AppTheme.primaryColor.withOpacity(0.1)),
                        columns: [
                          DataColumn(
                            label: TextWidget(
                              text: 'Receipt ID',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: AppTheme.primaryColor,
                            ),
                          ),
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
                              text: 'Customer',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          DataColumn(
                            label: TextWidget(
                              text: 'Payment',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          DataColumn(
                            label: TextWidget(
                              text: 'Total (P)',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          DataColumn(
                            label: TextWidget(
                              text: 'Actions',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                        rows: receipts.map((receipt) {
                          return DataRow(
                            cells: [
                              DataCell(
                                TextWidget(
                                  text: receipt['orderId'],
                                  fontSize: 14,
                                  fontFamily: 'Regular',
                                  color: Colors.grey[800],
                                ),
                              ),
                              DataCell(
                                TextWidget(
                                  text: DateFormat('MMM dd, yyyy HH:mm')
                                      .format(receipt['timestamp'].toDate()),
                                  fontSize: 14,
                                  fontFamily: 'Regular',
                                  color: Colors.grey[800],
                                ),
                              ),
                              DataCell(
                                TextWidget(
                                  text: receipt['buyer'],
                                  fontSize: 14,
                                  fontFamily: 'Regular',
                                  color: Colors.grey[800],
                                ),
                              ),
                              DataCell(
                                TextWidget(
                                  text: receipt['status'] == 'Accepted'
                                      ? 'Cash'
                                      : 'Unknown',
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
                                      color: AppTheme.primaryColor,
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
                                      textColor: AppTheme.primaryColor,
                                      label: 'Print',
                                      onPressed: () => _printReceipt(receipt),
                                      fontSize: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
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
