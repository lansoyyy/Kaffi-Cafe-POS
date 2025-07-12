import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Future<void> _deleteTransaction(String orderId, String itemName) async {
    try {
      await _firestore.collection('orders').doc(orderId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Transaction for $itemName deleted successfully',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: bayanihanBlue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error deleting transaction: $e',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: festiveRed,
        ),
      );
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('orders')
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

      List<List<dynamic>> csvData = [
        ['Order ID', 'Item', 'Quantity', 'Price', 'Date', 'Customer'],
      ];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;
        for (var item in items) {
          csvData.add([
            data['orderId'],
            item['name'],
            item['quantity'],
            item['price'].toStringAsFixed(2),
            DateFormat('MMM dd, yyyy HH:mm').format(data['timestamp'].toDate()),
            data['buyer'],
          ]);
        }
      }

      final csvString = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csvString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download',
            'transactions_${DateFormat('yyyyMMdd').format(_selectedDay!)}.csv')
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

  Future<void> _printTransactionSummary() async {
    final pdf = pw.Document();
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('orders')
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

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                    'Transaction Summary - ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...snapshot.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Order ID: ${data['orderId']}',
                          style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('Customer: ${data['buyer']}',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(
                          'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(data['timestamp'].toDate())}',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Items:',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ...data['items'].map<pw.Widget>((item) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Text(
                              '${item['name']} x${item['quantity']} - P${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          )),
                      pw.SizedBox(height: 10),
                    ],
                  );
                }).toList(),
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
            text: 'Error printing summary: $e',
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
        backgroundColor: bayanihanBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        title: TextWidget(
          text: 'Transactions',
          fontSize: 20,
          fontFamily: 'Bold',
          color: Colors.white,
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
                child: TableCalendar(
                  firstDay: DateTime.utc(2010, 10, 16),
                  lastDay: DateTime.utc(2050, 3, 14),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarStyle: const CalendarStyle(
                    cellMargin: EdgeInsets.zero,
                    cellPadding: EdgeInsets.zero,
                    tablePadding: EdgeInsets.zero,
                    outsideDaysVisible: false,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    leftChevronMargin: EdgeInsets.zero,
                    rightChevronMargin: EdgeInsets.zero,
                    headerPadding: EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  availableGestures: AvailableGestures.horizontalSwipe,
                  calendarFormat: CalendarFormat.month,
                  rowHeight: 40,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWidget(
                            text:
                                'Transactions for ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
                            fontSize: 18,
                            fontFamily: 'Bold',
                            color: bayanihanBlue,
                          ),
                          Row(
                            children: [
                              ButtonWidget(
                                width: 125,
                                radius: 8,
                                color: bayanihanBlue,
                                textColor: Colors.white,
                                label: 'Print Summary',
                                onPressed: _printTransactionSummary,
                                fontSize: 12,
                              ),
                              const SizedBox(width: 8),
                              ButtonWidget(
                                width: 125,
                                radius: 8,
                                color: bayanihanBlue,
                                textColor: Colors.white,
                                label: 'Export CSV',
                                onPressed: _exportToCSV,
                                fontSize: 12,
                              ),
                            ],
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
                                final items = data['items'] as List<dynamic>;
                                for (var item in items) {
                                  final category = item['category'] ?? 'Foods';
                                  categorizedItems[category]!.add({
                                    'name': item['name'],
                                    'quantity': item['quantity'],
                                    'price': item['price'],
                                    'orderId': order.id,
                                    'category': category,
                                  });
                                }
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: categorizedItems.entries.map((entry) {
                                  final category = entry.key;
                                  final items = entry.value;
                                  if (items.isEmpty) return const SizedBox();
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextWidget(
                                        text: category,
                                        fontSize: 20,
                                        fontFamily: 'Bold',
                                        color: bayanihanBlue,
                                      ),
                                      const SizedBox(height: 12),
                                      Table(
                                        border: TableBorder.all(
                                          color: bayanihanBlue.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        columnWidths: const {
                                          0: FlexColumnWidth(3),
                                          1: FlexColumnWidth(2),
                                          2: FlexColumnWidth(2),
                                          3: FixedColumnWidth(60),
                                        },
                                        children: [
                                          _buildTableHeader(),
                                          ...items.map((item) => _buildTableRow(
                                                item['name'],
                                                item['quantity'],
                                                item['price'],
                                                item['orderId'],
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

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: BoxDecoration(
        color: bayanihanBlue.withOpacity(0.1),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: 'Item',
            fontSize: 16,
            fontFamily: 'Bold',
            color: bayanihanBlue,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: 'Qty',
            fontSize: 16,
            fontFamily: 'Bold',
            color: bayanihanBlue,
            align: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: 'Price',
            fontSize: 16,
            fontFamily: 'Bold',
            color: bayanihanBlue,
            align: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: '',
            fontSize: 16,
            fontFamily: 'Bold',
            color: bayanihanBlue,
            align: TextAlign.center,
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(
      String item, int quantity, double price, String orderId) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: item,
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.grey[800],
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
            text: '₱${price.toStringAsFixed(2)}',
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
              Icons.delete,
              color: festiveRed,
              size: 20,
            ),
            onPressed: () => _deleteTransaction(orderId, item),
          ),
        ),
      ],
    );
  }
}
