import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _currentBranch;
  List<DocumentSnapshot> _reservations = [];
  bool _isLoadingReservations = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentBranch();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _getCurrentBranch() async {
    final currentBranch = await BranchService.getSelectedBranch();
    if (mounted) {
      setState(() {
        _currentBranch = currentBranch;
      });
    }
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

  // Dialog for adding a new order
  void _showAddOrderDialog(BuildContext context) {
    final buyerController = TextEditingController();
    final itemNameController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final List<Map<String, dynamic>> items = [];
    String selectedOrderType = 'Dine in'; // Default to Dine in

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: TextWidget(
          text: 'Add New Order',
          fontSize: 18,
          fontFamily: 'Bold',
          color: Colors.grey[800],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: buyerController,
                decoration: InputDecoration(
                  labelText: 'Buyer Name',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: itemNameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price per Item (P)',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Order Type Selection
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Order Type',
                      fontSize: 14,
                      fontFamily: 'Medium',
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedOrderType = 'Dine in';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedOrderType == 'Dine in'
                                    ? AppTheme.primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedOrderType == 'Dine in'
                                      ? AppTheme.primaryColor
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    color: selectedOrderType == 'Dine in'
                                        ? AppTheme.primaryColor
                                        : Colors.grey[600],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  TextWidget(
                                    text: 'Dine in',
                                    fontSize: 14,
                                    fontFamily: 'Medium',
                                    color: selectedOrderType == 'Dine in'
                                        ? AppTheme.primaryColor
                                        : Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedOrderType = 'Pickup';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedOrderType == 'Pickup'
                                    ? AppTheme.primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedOrderType == 'Pickup'
                                      ? AppTheme.primaryColor
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.takeout_dining,
                                    color: selectedOrderType == 'Pickup'
                                        ? AppTheme.primaryColor
                                        : Colors.grey[600],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  TextWidget(
                                    text: 'Pickup',
                                    fontSize: 14,
                                    fontFamily: 'Medium',
                                    color: selectedOrderType == 'Pickup'
                                        ? AppTheme.primaryColor
                                        : Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ButtonWidget(
                label: 'Add Item to Order',
                onPressed: () {
                  if (itemNameController.text.isEmpty ||
                      quantityController.text.isEmpty ||
                      priceController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: TextWidget(
                          text: 'Please fill in all item fields',
                          fontSize: 14,
                          fontFamily: 'Regular',
                          color: Colors.white,
                        ),
                        backgroundColor: Colors.red[600],
                      ),
                    );
                    return;
                  }
                  final quantity = int.tryParse(quantityController.text);
                  final price = double.tryParse(priceController.text);
                  if (quantity == null ||
                      quantity <= 0 ||
                      price == null ||
                      price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: TextWidget(
                          text: 'Invalid quantity or price',
                          fontSize: 14,
                          fontFamily: 'Regular',
                          color: Colors.white,
                        ),
                        backgroundColor: Colors.red[600],
                      ),
                    );
                    return;
                  }
                  items.add({
                    'name': itemNameController.text,
                    'quantity': quantity,
                    'price': price,
                  });
                  itemNameController.clear();
                  quantityController.clear();
                  priceController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: TextWidget(
                        text: 'Item added to order',
                        fontSize: 14,
                        fontFamily: 'Regular',
                        color: Colors.white,
                      ),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                },
                color: AppTheme.primaryColor,
                textColor: Colors.white,
                fontSize: 14,
                radius: 8,
                height: 40,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Cancel',
              fontSize: 14,
              fontFamily: 'Medium',
              color: Colors.grey[600],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (buyerController.text.isEmpty || items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Please enter buyer name and add at least one item',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.white,
                    ),
                    backgroundColor: Colors.red[600],
                  ),
                );
                return;
              }
              try {
                final total = items.fold<double>(
                    0, (sum, item) => sum + item['quantity'] * item['price']);
                final orderId =
                    (await _firestore.collection('orders').get()).docs.length +
                        1001;
                await _firestore.collection('orders').add({
                  'orderId': orderId.toString(),
                  'buyer': buyerController.text,
                  'items': items,
                  'total': total,
                  'status': 'Pending',
                  'timestamp': FieldValue.serverTimestamp(),
                  'branch': _currentBranch,
                  'orderType': selectedOrderType,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Order added successfully',
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
                      text: 'Error adding order: $e',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.white,
                    ),
                    backgroundColor: Colors.red[600],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: TextWidget(
              text: 'Submit Order',
              fontSize: 14,
              fontFamily: 'Medium',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Generate order PDF
  Future<pw.Document> _generateOrderPdf(Map<String, dynamic> orderData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Kaffi Cafe - Order Details',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Order ID: ${orderData['orderId']}',
                  style: const pw.TextStyle(fontSize: 14)),
              pw.Text(
                  'Date: ${DateFormat('MMM dd, yyyy HH:mm').format((orderData['timestamp'] as Timestamp).toDate())}',
                  style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text('Buyer: ${orderData['buyer']}',
                  style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text('Items:',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              ...(orderData['items'] as List<dynamic>)
                  .map<pw.Widget>((item) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text('${item['name']}',
                                  style: const pw.TextStyle(fontSize: 12)),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text('x${item['quantity']}',
                                  style: const pw.TextStyle(fontSize: 12)),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                  'P${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                  style: const pw.TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      )),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total:',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('P${orderData['total'].toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // Generate receipt PDF
  Future<pw.Document> _generateReceiptPdf(
      Map<String, dynamic> orderData) async {
    final pdf = pw.Document();

    // Get current staff name
    final staffName = await _getCurrentStaffName();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Kaffi Cafe',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Official Receipt',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Order #${orderData['orderId']}',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.Text(
                  'Date: ${DateFormat('MMM dd, yyyy HH:mm').format((orderData['timestamp'] as Timestamp).toDate())}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 15),
              pw.Text('Buyer: ${orderData['buyer']}',
                  style: const pw.TextStyle(fontSize: 10)),
              // Only show staff name if not admin
              if (staffName.isNotEmpty) ...[
                pw.Text('Served by: $staffName',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
              pw.SizedBox(height: 15),
              pw.Divider(),
              ...(orderData['items'] as List<dynamic>)
                  .map<pw.Widget>((item) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                  '${item['name']} x${item['quantity']}',
                                  style: const pw.TextStyle(fontSize: 10)),
                            ),
                            pw.Text(
                                'P${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      )),
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('P${orderData['total'].toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Thank you for your purchase!',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Please come again.',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // Show payment success dialog
  void _showPaymentSuccessDialog(Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 500,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    TextWidget(
                      text: 'Order Processed',
                      fontSize: 24,
                      fontFamily: 'Bold',
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              // Order details
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Order #${orderData['orderId']}',
                      fontSize: 18,
                      fontFamily: 'Bold',
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text: 'Buyer: ${orderData['buyer']}',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text:
                          'Date: ${DateFormat('MMM dd, yyyy HH:mm').format((orderData['timestamp'] as Timestamp).toDate())}',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.grey[700],
                    ),
                    TextWidget(
                      text: 'Remarks: ${orderData['specialRemarks']}',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.grey[700],
                    ),

                    const SizedBox(height: 16),
                    TextWidget(
                      text: 'Items:',
                      fontSize: 16,
                      fontFamily: 'Bold',
                      color: Colors.grey[800],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Column(
                          children: (orderData['items'] as List<dynamic>)
                              .map<Widget>((item) {
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
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
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 16),
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWidget(
                            text: 'Total:',
                            fontSize: 16,
                            fontFamily: 'Bold',
                            color: Colors.grey[800],
                          ),
                          TextWidget(
                            text: 'P${orderData['total'].toStringAsFixed(2)}',
                            fontSize: 16,
                            fontFamily: 'Bold',
                            color: Colors.grey[800],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ButtonWidget(
                      radius: 8,
                      color: Colors.grey[300]!,
                      textColor: AppTheme.primaryColor,
                      label: 'Print Order',
                      onPressed: () async {
                        try {
                          final pdf = await _generateOrderPdf(orderData);
                          await Printing.layoutPdf(
                              onLayout: (PdfPageFormat format) async =>
                                  pdf.save());
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: TextWidget(
                                  text: 'Error printing order: $e',
                                  fontSize: 14,
                                  fontFamily: 'Regular',
                                  color: Colors.white,
                                ),
                                backgroundColor: Colors.red[600],
                              ),
                            );
                          }
                        }
                      },
                      fontSize: 14,
                      width: 120,
                      height: 40,
                    ),
                    ButtonWidget(
                      radius: 8,
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      label: 'Print Receipt',
                      onPressed: () async {
                        try {
                          final pdf = await _generateReceiptPdf(orderData);
                          await Printing.layoutPdf(
                              onLayout: (PdfPageFormat format) async =>
                                  pdf.save());
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: TextWidget(
                                  text: 'Error printing receipt: $e',
                                  fontSize: 14,
                                  fontFamily: 'Regular',
                                  color: Colors.white,
                                ),
                                backgroundColor: Colors.red[600],
                              ),
                            );
                          }
                        }
                      },
                      fontSize: 14,
                      width: 120,
                      height: 40,
                    ),
                    ButtonWidget(
                      radius: 8,
                      color: Colors.red[600]!,
                      textColor: Colors.white,
                      label: 'Close',
                      onPressed: () => Navigator.pop(context),
                      fontSize: 14,
                      width: 120,
                      height: 40,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show pending order details dialog
  void _showPendingOrderDialog(DocumentSnapshot order) {
    final data = order.data() as Map<String, dynamic>;
    final items =
        (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 500,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pending_actions,
                          color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      TextWidget(
                        text: 'Pending Order Details',
                        fontSize: 24,
                        fontFamily: 'Bold',
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                // Order details
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: 'Order #${data['orderId']}',
                        fontSize: 18,
                        fontFamily: 'Bold',
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      TextWidget(
                        text: 'Buyer: ${data['buyer']}',
                        fontSize: 14,
                        fontFamily: 'Regular',
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 8),
                      TextWidget(
                        text:
                            'Date: ${DateFormat('MMM dd, yyyy HH:mm').format((data['timestamp'] as Timestamp).toDate())}',
                        fontSize: 14,
                        fontFamily: 'Regular',
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 8),
                      if (data['paymentMethod'] != null) ...[
                        TextWidget(
                          text: 'Payment Method: ${data['paymentMethod']}',
                          fontSize: 14,
                          fontFamily: 'Regular',
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextWidget(
                        text: 'Remarks: ${data['specialRemarks']}',
                        fontSize: 14,
                        fontFamily: 'Regular',
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 8),
                      // Display voucher information if available
                      if (data['voucherCode'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.local_offer,
                                  color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text:
                                          'Voucher Applied: ${data['voucherCode']}',
                                      fontSize: 14,
                                      fontFamily: 'Medium',
                                      color: Colors.green[700],
                                    ),
                                    if (data['voucherDiscount'] != null)
                                      TextWidget(
                                        text:
                                            'Discount: P${data['voucherDiscount'].toStringAsFixed(2)}',
                                        fontSize: 12,
                                        fontFamily: 'Regular',
                                        color: Colors.green[600],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 16),
                      TextWidget(
                        text: 'Items:',
                        fontSize: 16,
                        fontFamily: 'Bold',
                        color: Colors.grey[800],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: SingleChildScrollView(
                          child: Column(
                            children: items.map<Widget>((item) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
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
                                          color: Colors.grey[700],
                                        ),
                                        const SizedBox(width: 16),
                                        TextWidget(
                                          text:
                                              'P${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                          fontSize: 14,
                                          fontFamily: 'Regular',
                                          color: Colors.grey[800],
                                        ),
                                      ],
                                    ),
                                    // Display customization details if available
                                    if (item['customizations'] != null) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TextWidget(
                                              text: 'Customizations:',
                                              fontSize: 12,
                                              fontFamily: 'Medium',
                                              color: Colors.blue[700],
                                            ),
                                            const SizedBox(height: 2),
                                            _buildCustomizationDetails(
                                                item['customizations']),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(
                              text: 'Total:',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: Colors.grey[800],
                            ),
                            TextWidget(
                              text: 'P${data['total'].toStringAsFixed(2)}',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: Colors.grey[800],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ButtonWidget(
                        radius: 8,
                        color: Colors.orange,
                        textColor: Colors.white,
                        label: data['orderType'] == 'Dine in'
                            ? 'Order Received'
                            : 'Prepare Order',
                        onPressed: () {
                          Navigator.pop(context);
                          if (data['orderType'] == 'Dine in') {
                            // For Dine in orders, show reservation dialog
                            final orderDataWithId =
                                Map<String, dynamic>.from(data);
                            orderDataWithId['docId'] = order.id;
                            _showOrderReceivedSuccessDialog(orderDataWithId);
                          } else {
                            // For Pickup orders, advance to preparing
                            _advanceOrderStatus(order.id, 'Pending');
                          }
                        },
                        fontSize: 14,
                        width: 140,
                        height: 40,
                      ),
                      ButtonWidget(
                        radius: 8,
                        color: AppTheme.primaryColor,
                        textColor: Colors.white,
                        label: 'Print Order',
                        onPressed: () async {
                          try {
                            final pdf = await _generateOrderPdf(data);
                            await Printing.layoutPdf(
                                onLayout: (PdfPageFormat format) async =>
                                    pdf.save());
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: TextWidget(
                                    text: 'Error printing order: $e',
                                    fontSize: 14,
                                    fontFamily: 'Regular',
                                    color: Colors.white,
                                  ),
                                  backgroundColor: Colors.red[600],
                                ),
                              );
                            }
                          }
                        },
                        fontSize: 14,
                        width: 140,
                        height: 40,
                      ),
                      ButtonWidget(
                        radius: 8,
                        color: Colors.grey[300]!,
                        textColor: Colors.grey[700]!,
                        label: 'Close',
                        onPressed: () => Navigator.pop(context),
                        fontSize: 14,
                        width: 140,
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show preparing order details dialog
  void _showPreparingOrderDialog(DocumentSnapshot order) {
    final data = order.data() as Map<String, dynamic>;
    final items =
        (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    // Calculate the deadline time (20 minutes after order creation)
    final Timestamp orderTimestamp = data['timestamp'] as Timestamp;
    final DateTime orderTime = orderTimestamp.toDate();
    final DateTime deadlineTime = orderTime.add(const Duration(minutes: 20));
    final String formattedDeadline =
        DateFormat('MMM dd, yyyy HH:mm').format(deadlineTime);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 500,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant,
                          color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      TextWidget(
                        text: 'Preparing Order Details',
                        fontSize: 24,
                        fontFamily: 'Bold',
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                // Pre-order preparation notice
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: Colors.orange[700], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text:
                                  'Kindly prepare this pre-order for completion',
                              fontSize: 14,
                              fontFamily: 'Medium',
                              color: Colors.orange[700],
                            ),
                            TextWidget(
                              text: 'before $formattedDeadline',
                              fontSize: 14,
                              fontFamily: 'Medium',
                              color: Colors.orange[700],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Order details
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: 'Order #${data['orderId']}',
                        fontSize: 18,
                        fontFamily: 'Bold',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      TextWidget(
                        text: 'Buyer: ${data['buyer']}',
                        fontSize: 14,
                        fontFamily: 'Regular',
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 8),
                      if (data['paymentMethod'] != null) ...[
                        TextWidget(
                          text: 'Payment Method: ${data['paymentMethod']}',
                          fontSize: 14,
                          fontFamily: 'Regular',
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextWidget(
                        text: 'Remarks: ${data['specialRemarks']}',
                        fontSize: 14,
                        fontFamily: 'Regular',
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 8),
                      // Display voucher information if available
                      if (data['voucherCode'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.local_offer,
                                  color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text:
                                          'Voucher Applied: ${data['voucherCode']}',
                                      fontSize: 14,
                                      fontFamily: 'Medium',
                                      color: Colors.green[700],
                                    ),
                                    if (data['voucherDiscount'] != null)
                                      TextWidget(
                                        text:
                                            'Discount: P${data['voucherDiscount'].toStringAsFixed(2)}',
                                        fontSize: 12,
                                        fontFamily: 'Regular',
                                        color: Colors.green[600],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 16),
                      TextWidget(
                        text: 'Items:',
                        fontSize: 16,
                        fontFamily: 'Bold',
                        color: Colors.grey[800],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: SingleChildScrollView(
                          child: Column(
                            children: items.map<Widget>((item) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
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
                                          color: Colors.grey[700],
                                        ),
                                        const SizedBox(width: 16),
                                        TextWidget(
                                          text:
                                              'P${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                          fontSize: 14,
                                          fontFamily: 'Regular',
                                          color: Colors.grey[800],
                                        ),
                                      ],
                                    ),
                                    // Display customization details if available
                                    if (item['customizations'] != null) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TextWidget(
                                              text: 'Customizations:',
                                              fontSize: 12,
                                              fontFamily: 'Medium',
                                              color: Colors.blue[700],
                                            ),
                                            const SizedBox(height: 2),
                                            _buildCustomizationDetails(
                                                item['customizations']),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(
                              text: 'Total:',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: Colors.grey[800],
                            ),
                            TextWidget(
                              text: 'P${data['total'].toStringAsFixed(2)}',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: Colors.grey[800],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ButtonWidget(
                        radius: 8,
                        color: Colors.blue,
                        textColor: Colors.white,
                        label: 'Ready for Pickup',
                        onPressed: () {
                          Navigator.pop(context);
                          _advanceOrderStatus(order.id, 'Accepted');
                        },
                        fontSize: 14,
                        width: 140,
                        height: 40,
                      ),
                      ButtonWidget(
                        radius: 8,
                        color: AppTheme.primaryColor,
                        textColor: Colors.white,
                        label: 'Print Order',
                        onPressed: () async {
                          try {
                            final pdf = await _generateOrderPdf(data);
                            await Printing.layoutPdf(
                                onLayout: (PdfPageFormat format) async =>
                                    pdf.save());
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: TextWidget(
                                    text: 'Error printing order: $e',
                                    fontSize: 14,
                                    fontFamily: 'Regular',
                                    color: Colors.white,
                                  ),
                                  backgroundColor: Colors.red[600],
                                ),
                              );
                            }
                          }
                        },
                        fontSize: 14,
                        width: 140,
                        height: 40,
                      ),
                      ButtonWidget(
                        radius: 8,
                        color: Colors.grey[300]!,
                        textColor: Colors.grey[700]!,
                        label: 'Close',
                        onPressed: () => Navigator.pop(context),
                        fontSize: 14,
                        width: 140,
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show ready for pickup order details dialog
  void _showReadyOrderDialog(DocumentSnapshot order) {
    final data = order.data() as Map<String, dynamic>;
    final items =
        (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 500,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      TextWidget(
                        text: 'Ready for Pickup Order Details',
                        fontSize: 24,
                        fontFamily: 'Bold',
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                // Order details
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: 'Order #${data['orderId']}',
                        fontSize: 18,
                        fontFamily: 'Bold',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      TextWidget(
                        text: 'Buyer: ${data['buyer']}',
                        fontSize: 14,
                        fontFamily: 'Regular',
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 8),
                      TextWidget(
                        text:
                            'Date: ${DateFormat('MMM dd, yyyy HH:mm').format((data['timestamp'] as Timestamp).toDate())}',
                        fontSize: 14,
                        fontFamily: 'Regular',
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 8),
                      if (data['paymentMethod'] != null) ...[
                        TextWidget(
                          text: 'Payment Method: ${data['paymentMethod']}',
                          fontSize: 14,
                          fontFamily: 'Regular',
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextWidget(
                        text: 'Remarks: ${data['specialRemarks']}',
                        fontSize: 14,
                        fontFamily: 'Regular',
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 8),
                      // Display voucher information if available
                      if (data['voucherCode'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.local_offer,
                                  color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text:
                                          'Voucher Applied: ${data['voucherCode']}',
                                      fontSize: 14,
                                      fontFamily: 'Medium',
                                      color: Colors.green[700],
                                    ),
                                    if (data['voucherDiscount'] != null)
                                      TextWidget(
                                        text:
                                            'Discount: P${data['voucherDiscount'].toStringAsFixed(2)}',
                                        fontSize: 12,
                                        fontFamily: 'Regular',
                                        color: Colors.green[600],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 16),
                      TextWidget(
                        text: 'Items:',
                        fontSize: 16,
                        fontFamily: 'Bold',
                        color: Colors.grey[800],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: SingleChildScrollView(
                          child: Column(
                            children: items.map<Widget>((item) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
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
                                          color: Colors.grey[700],
                                        ),
                                        const SizedBox(width: 16),
                                        TextWidget(
                                          text:
                                              'P${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                          fontSize: 14,
                                          fontFamily: 'Regular',
                                          color: Colors.grey[800],
                                        ),
                                      ],
                                    ),
                                    // Display customization details if available
                                    if (item['customizations'] != null) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TextWidget(
                                              text: 'Customizations:',
                                              fontSize: 12,
                                              fontFamily: 'Medium',
                                              color: Colors.blue[700],
                                            ),
                                            const SizedBox(height: 2),
                                            _buildCustomizationDetails(
                                                item['customizations']),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(
                              text: 'Total:',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: Colors.grey[800],
                            ),
                            TextWidget(
                              text: 'P${data['total'].toStringAsFixed(2)}',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: Colors.grey[800],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ButtonWidget(
                        radius: 8,
                        color: Colors.green,
                        textColor: Colors.white,
                        label: 'Completed',
                        onPressed: () {
                          Navigator.pop(context);
                          // For Ready for Pickup orders, just mark as completed
                          _updateOrderStatus(order.id, 'Completed');
                        },
                        fontSize: 14,
                        width: 140,
                        height: 40,
                      ),
                      ButtonWidget(
                        radius: 8,
                        color: Colors.orange,
                        textColor: Colors.white,
                        label: 'Print Receipt',
                        onPressed: () async {
                          try {
                            final pdf = await _generateReceiptPdf(data);
                            await Printing.layoutPdf(
                                onLayout: (PdfPageFormat format) async =>
                                    pdf.save());
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: TextWidget(
                                    text: 'Error printing receipt: $e',
                                    fontSize: 14,
                                    fontFamily: 'Regular',
                                    color: Colors.white,
                                  ),
                                  backgroundColor: Colors.red[600],
                                ),
                              );
                            }
                          }
                        },
                        fontSize: 14,
                        width: 140,
                        height: 40,
                      ),
                      ButtonWidget(
                        radius: 8,
                        color: Colors.grey[300]!,
                        textColor: Colors.grey[700]!,
                        label: 'Close',
                        onPressed: () => Navigator.pop(context),
                        fontSize: 14,
                        width: 140,
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show order received success dialog
  void _showOrderReceivedSuccessDialog(Map<String, dynamic> orderData) async {
    print(orderData);
    print(
        'Showing order received success dialog for order #${orderData['orderId']}');

    // For Dine in orders from Pending status, check for reservation
    if (orderData['orderType'] == 'Dine in' &&
        orderData['status'] == 'Pending') {
      // Check if this is a dine-in order with a reservation
      final reservationData = await _fetchReservationDetails(orderData);

      if (reservationData != null) {
        print('Reservation found, showing reservation dialog');
        // Show reservation dialog first
        _showReservationDialog(orderData, reservationData);
        return;
      }
    }

    print(
        'No reservation found or not a Dine in pending order, showing regular order received dialog');
    // Show regular order received dialog
    _showRegularOrderReceivedDialog(orderData);
  }

  // Show regular order received dialog (for orders without reservations)
  void _showRegularOrderReceivedDialog(Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    TextWidget(
                      text: 'Order Received Successfully!',
                      fontSize: 20,
                      fontFamily: 'Bold',
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              // Order details
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Order #${orderData['orderId']}',
                      fontSize: 18,
                      fontFamily: 'Bold',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text: 'Buyer: ${orderData['buyer']}',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text: 'Total: P${orderData['total'].toStringAsFixed(2)}',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextWidget(
                        text: 'Thank you for your order!',
                        fontSize: 16,
                        fontFamily: 'Medium',
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              // Close button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: ButtonWidget(
                  radius: 8,
                  color: Colors.green,
                  textColor: Colors.white,
                  label: 'Close',
                  onPressed: () {
                    Navigator.pop(context);
                    // Update order status to completed
                    _updateOrderStatus(orderData['docId'] ?? '', 'Completed');
                  },
                  fontSize: 14,
                  width: 120,
                  height: 40,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fetch reservation details associated with an order
  Future<Map<String, dynamic>?> _fetchReservationDetails(
      Map<String, dynamic> orderData) async {
    print(orderData);
    try {
      // Debug print to check order data
      print('Order data for reservation check:');
      print('Order Type: ${orderData['orderType']}');
      print('Reservation Table ID: ${orderData['reservationTableId']}');
      print('Reservation Date: ${orderData['reservationDate']}');
      print('Reservation Time: ${orderData['reservationTime']}');

      // Check if this is a dine-in order with reservation details
      if (orderData['orderType'] == 'Dine in' &&
          orderData['reservationTableId'] != null &&
          orderData['reservationDate'] != null &&
          orderData['reservationTime'] != null) {
        print(
            'Dine-in order with reservation details found. Querying reservations...');

        // Convert date format from dd/MM/yyyy to yyyy-MM-dd to match Firestore format
        String orderDate = orderData['reservationDate'].trim();
        String formattedDate = orderDate; // Default to original format

        try {
          // Parse the date from dd/MM/yyyy format
          final parts = orderDate.split('/');
          if (parts.length == 3) {
            final day = parts[0].padLeft(2, '0');
            final month = parts[1].padLeft(2, '0');
            final year = parts[2];
            formattedDate = '$year-$month-$day';
            print('Converted date from $orderDate to $formattedDate');
          }
        } catch (e) {
          print('Error converting date format: $e');
        }

        // Query the reservations collection
        final reservationQuery = await _firestore
            .collection('reservations')
            .where('tableId', isEqualTo: orderData['reservationTableId'])
            .where('date', isEqualTo: formattedDate)
            .where('timeSlot', isEqualTo: orderData['reservationTime'])
            .limit(1) // Remove status filter to get any reservation
            .get();

        print('Found ${reservationQuery.docs.length} reservation documents');

        if (reservationQuery.docs.isNotEmpty) {
          final reservationDoc = reservationQuery.docs.first;
          final reservationData = reservationDoc.data() as Map<String, dynamic>;

          print('Reservation document data: $reservationData');

          // Handle different possible structures
          Map<String, dynamic>? reservation;
          String? status;
          String? customerName;

          // Check if reservation data is nested under 'reservation' field
          if (reservationData.containsKey('reservation') &&
              reservationData['reservation'] != null) {
            print('Reservation data is nested under "reservation" field');
            reservation =
                reservationData['reservation'] as Map<String, dynamic>;
            status = reservation['status'];
            customerName = reservation['name'];
          }
          // Check if reservation data is directly in the document
          else {
            print('Reservation data is nested under "reservation" fiasdeld');
            reservation = reservationData;
            status = reservationData['status'];
            customerName = reservationData['name'];
          }

          print('Reservation status: $status');
          print('Customer name: $customerName');

          // Return reservation details with document ID
          return {
            'docId': reservationDoc.id,
            'tableId': orderData['reservationTableId'],
            'tableName': orderData['reservationTableName'] ?? 'Unknown Table',
            'date': orderData['reservationDate'],
            'time': orderData['reservationTime'],
            'guests': orderData['reservationGuests'] ?? 1,
            'status': status ?? 'unknown',
            'customerName': customerName ?? 'Unknown Customer',
          };
        }
      }
      return null;
    } catch (e) {
      print('Error fetching reservation details: $e');
      return null;
    }
  }

  // Update reservation status
  Future<void> _updateReservationStatus(
      String reservationDocId, String status) async {
    try {
      // First, get the reservation document to check its structure
      final reservationDoc = await _firestore
          .collection('reservations')
          .doc(reservationDocId)
          .get();
      final reservationData = reservationDoc.data() as Map<String, dynamic>;

      // Check if reservation data is nested under 'reservation' field
      if (reservationData.containsKey('reservation') &&
          reservationData['reservation'] != null) {
        // Update nested structure
        await _firestore
            .collection('reservations')
            .doc(reservationDocId)
            .update({
          'reservation.status': status,
          'updatedAt': FieldValue.serverTimestamp(),
          'confirmedAt':
              status == 'confirmed' ? FieldValue.serverTimestamp() : null,
        });
      }
      // Check if reservation data is directly in the document
      else {
        // Update direct structure
        await _firestore
            .collection('reservations')
            .doc(reservationDocId)
            .update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
          'confirmedAt':
              status == 'confirmed' ? FieldValue.serverTimestamp() : null,
        });
      }

      print('Reservation status updated to: $status');
    } catch (e) {
      print('Error updating reservation status: $e');
    }
  }

  // Show reservation confirmation dialog
  void _showReservationDialog(
      Map<String, dynamic> orderData, Map<String, dynamic> reservationData) {
    print(
        'Showing reservation dialog for table ${reservationData['tableName']}');

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 500,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_seat, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    TextWidget(
                      text: 'Table Reservation',
                      fontSize: 24,
                      fontFamily: 'Bold',
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              // Reservation details
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Order #${orderData['orderId']}',
                      fontSize: 18,
                      fontFamily: 'Bold',
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.table_restaurant,
                                  color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              TextWidget(
                                text: 'Table: ${reservationData['tableName']}',
                                fontSize: 16,
                                fontFamily: 'Bold',
                                color: Colors.blue[700],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.person,
                                  color: Colors.grey[700], size: 20),
                              const SizedBox(width: 8),
                              TextWidget(
                                text:
                                    'Customer: ${reservationData['customerName']}',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Colors.grey[700], size: 20),
                              const SizedBox(width: 8),
                              TextWidget(
                                text: 'Date: ${reservationData['date']}',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  color: Colors.grey[700], size: 20),
                              const SizedBox(width: 8),
                              TextWidget(
                                text: 'Time: ${reservationData['time']}',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.group,
                                  color: Colors.grey[700], size: 20),
                              const SizedBox(width: 8),
                              TextWidget(
                                text: 'Guests: ${reservationData['guests']}',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextWidget(
                      text:
                          'Please confirm or reject the table reservation for this order.',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ),
              // Action buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ButtonWidget(
                      radius: 8,
                      color: Colors.red[600]!,
                      textColor: Colors.white,
                      label: 'Reject',
                      onPressed: () async {
                        Navigator.pop(context);
                        await _updateReservationStatus(
                            reservationData['docId'], 'cancelled');

                        // Continue with order completion
                        await _updateOrderStatus(
                            orderData['docId'] ?? '', 'Completed');

                        // Check if context is still mounted before showing SnackBar
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: TextWidget(
                                text:
                                    'Reservation rejected and order completed',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.white,
                              ),
                              backgroundColor: Colors.red[600],
                            ),
                          );
                        }
                      },
                      fontSize: 14,
                      width: 120,
                      height: 40,
                    ),
                    ButtonWidget(
                      radius: 8,
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      label: 'Confirm',
                      onPressed: () async {
                        Navigator.pop(context);
                        await _updateReservationStatus(
                            reservationData['docId'], 'confirmed');

                        // Continue with order completion
                        await _updateOrderStatus(
                            orderData['docId'] ?? '', 'Accepted');

                        // Check if context is still mounted before showing SnackBar
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: TextWidget(
                                text:
                                    'Reservation confirmed and order completed',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.white,
                              ),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          );
                        }
                      },
                      fontSize: 14,
                      width: 120,
                      height: 40,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update order status
  Future<void> _updateOrderStatus(String docId, String status) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(docId).get();
      final orderData = orderDoc.data() as Map<String, dynamic>;

      await _firestore.collection('orders').doc(docId).update({
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Show payment success dialog when order is accepted (Preparing)
      if (status == 'Accepted' && context.mounted) {
        _showPaymentSuccessDialog(orderData);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text:
                  'Order status updated to ${_mapStatusToUI(status)} successfully',
              fontSize: 14,
              fontFamily: 'Regular',
              color: Colors.white,
            ),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: 'Error updating order: $e',
              fontSize: 14,
              fontFamily: 'Regular',
              color: Colors.white,
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  // Delete order
  Future<void> _deleteOrder(String docId) async {
    try {
      await _firestore.collection('orders').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Order marked as unclaimed!',
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
            text: 'Error marking order as unclaimed: $e',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  // Map database status to UI status
  String _mapStatusToUI(String dbStatus) {
    switch (dbStatus) {
      case 'Pending':
        return 'On Hold';
      case 'Accepted':
        return 'Preparing';
      case 'Ready to Pickup':
        return 'Ready to Pickup';
      case 'Completed':
        return 'Completed';
      default:
        return dbStatus;
    }
  }

  // Get status color
  Color _getStatusColor(String uiStatus) {
    switch (uiStatus) {
      case 'On Hold':
        return Colors.orange; // Orange for On Hold
      case 'Preparing':
        return Colors.blue; // Blue for Preparing
      case 'Ready to Pickup':
        return Colors.green; // Green for Ready to Pickup
      case 'Completed':
        return Colors.grey; // Gray for Completed
      default:
        return Colors.orange;
    }
  }

  // Advance order to next status
  Future<void> _advanceOrderStatus(String docId, String currentStatus) async {
    String newStatus;
    switch (currentStatus) {
      case 'Pending': // On Hold
        newStatus = 'Accepted'; // Preparing
        break;
      case 'Accepted': // Preparing
        newStatus = 'Ready to Pickup';
        break;
      case 'Ready to Pickup':
        newStatus = 'Completed';
        break;
      default:
        return; // Don't advance for unknown statuses
    }
    await _updateOrderStatus(docId, newStatus);
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextWidget(
              text: 'Orders',
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
            const SizedBox(width: 20),
            Container(
              width: 350,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  hintText: 'Search orders...',
                  hintStyle: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Regular',
                    fontSize: 16,
                  ),
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
        actions: [
          ButtonWidget(
            label: 'Add Order',
            onPressed: () => _showAddOrderDialog(context),
            color: Colors.white,
            textColor: AppTheme.primaryColor,
            fontSize: 14,
            radius: 10,
            height: 40,
            width: 120,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Tab bar for Dine in and Pickup
          Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontSize: 16,
                fontFamily: 'Bold',
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontFamily: 'Medium',
              ),
              tabs: [
                Tab(
                  child: SizedBox(
                    width: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant),
                        SizedBox(
                          width: 10,
                        ),
                        Text('Dine in'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: SizedBox(
                    width: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.takeout_dining),
                        SizedBox(
                          width: 10,
                        ),
                        Text('Pickup'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tab bar view
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Dine in orders tab
                _buildOrdersTab('Dine in'),
                // Pickup orders tab
                _buildOrdersTab('Pickup'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build orders tab for specific order type
  Widget _buildOrdersTab(String orderType) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('orders')
            .where('branch', isEqualTo: _currentBranch)
            .where('orderType', isEqualTo: orderType)
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

          // Filter orders and count by status
          final allOrders = snapshot.data!.docs;

          // Apply search filter if there's a search query
          List<DocumentSnapshot> searchFilteredOrders = allOrders;
          if (_searchQuery.isNotEmpty) {
            searchFilteredOrders = allOrders.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final orderId = data['orderId']?.toString().toLowerCase() ?? '';
              final buyer = data['buyer']?.toString().toLowerCase() ?? '';
              return orderId.contains(_searchQuery.toLowerCase()) ||
                  buyer.contains(_searchQuery.toLowerCase());
            }).toList();
          }

          // Filter by status after search filtering
          final pendingOrders = searchFilteredOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Pending';
            return status == 'Pending';
          }).toList();

          final acceptedOrders = searchFilteredOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Pending';
            return status == 'Accepted';
          }).toList();

          final readyOrders = searchFilteredOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Pending';
            return status == 'Ready to Pickup';
          }).toList();

          final completedOrders = allOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Pending';
            return status == 'Completed';
          }).toList();

          return Column(
            children: [
              // Status Counts Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusCountCard(
                        'On Hold', pendingOrders.length, Colors.orange),
                    _buildStatusCountCard(
                        'Preparing', acceptedOrders.length, Colors.blue),
                    _buildStatusCountCard(
                        'Ready', readyOrders.length, Colors.green),
                    _buildStatusCountCard(
                        'Completed', completedOrders.length, Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Three Column Layout for Orders
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pending Orders Column
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.pending,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  TextWidget(
                                    text: 'Pending Orders',
                                    fontSize: 16,
                                    fontFamily: 'Bold',
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: pendingOrders.isEmpty
                                    ? Center(
                                        child: TextWidget(
                                          text: 'No pending orders',
                                          fontSize: 14,
                                          fontFamily: 'Regular',
                                          color: Colors.grey[500],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: pendingOrders.length,
                                        itemBuilder: (context, index) {
                                          final order = pendingOrders[index];
                                          return _buildOrderCard(order);
                                        },
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Preparing Orders Column
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  TextWidget(
                                    text: 'Preparing Orders',
                                    fontSize: 16,
                                    fontFamily: 'Bold',
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: acceptedOrders.isEmpty
                                    ? Center(
                                        child: TextWidget(
                                          text: 'No orders preparing',
                                          fontSize: 14,
                                          fontFamily: 'Regular',
                                          color: Colors.grey[500],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: acceptedOrders.length,
                                        itemBuilder: (context, index) {
                                          final order = acceptedOrders[index];
                                          return _buildOrderCard(order);
                                        },
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Ready for Pickup Orders Column
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  TextWidget(
                                    text: 'Ready for Pickup',
                                    fontSize: 16,
                                    fontFamily: 'Bold',
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: readyOrders.isEmpty
                                    ? Center(
                                        child: TextWidget(
                                          text: 'No orders ready',
                                          fontSize: 14,
                                          fontFamily: 'Regular',
                                          color: Colors.grey[500],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: readyOrders.length,
                                        itemBuilder: (context, index) {
                                          final order = readyOrders[index];
                                          return _buildOrderCard(order);
                                        },
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Build order card widget
  Widget _buildOrderCard(DocumentSnapshot order) {
    final data = order.data() as Map<String, dynamic>;
    final items =
        (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final status = data['status'] ?? 'Pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: () {
            if (status == 'Pending') {
              _showPendingOrderDialog(order);
            } else if (status == 'Accepted') {
              _showPreparingOrderDialog(order);
            } else if (status == 'Ready to Pickup') {
              _showReadyOrderDialog(order);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextWidget(
                        text: 'Order #${data['orderId'] ?? 'N/A'}',
                        fontSize: 16,
                        fontFamily: 'Bold',
                        color: Colors.grey[800],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_mapStatusToUI(status))
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(_mapStatusToUI(status)),
                          width: 1,
                        ),
                      ),
                      child: TextWidget(
                        text: _mapStatusToUI(status),
                        fontSize: 12,
                        fontFamily: 'Medium',
                        color: _getStatusColor(_mapStatusToUI(status)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    TextWidget(
                      text: 'Buyer: ${data['buyer'] ?? 'Unknown'}',
                      fontSize: 14,
                      fontFamily: 'Medium',
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: data['orderType'] == 'Dine in'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: data['orderType'] == 'Dine in'
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            data['orderType'] == 'Dine in'
                                ? Icons.restaurant
                                : Icons.takeout_dining,
                            size: 14,
                            color: data['orderType'] == 'Dine in'
                                ? Colors.blue[700]
                                : Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          TextWidget(
                            text: data['orderType'] ?? 'Unknown',
                            fontSize: 12,
                            fontFamily: 'Medium',
                            color: data['orderType'] == 'Dine in'
                                ? Colors.blue[700]
                                : Colors.green[700],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.grey, thickness: 0.5),
                const SizedBox(height: 8),
                // Order Items
                Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: TextWidget(
                              text: 'x${item['quantity'] ?? 1}',
                              fontSize: 12,
                              fontFamily: 'Bold',
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextWidget(
                              text: item['name'] ?? 'Unknown Item',
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: Colors.grey[800],
                            ),
                          ),
                          TextWidget(
                            text:
                                'P${(item['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                            fontSize: 12,
                            fontFamily: 'Regular',
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.grey, thickness: 0.5),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWidget(
                      text: 'Total',
                      fontSize: 14,
                      fontFamily: 'Bold',
                      color: Colors.grey[800],
                    ),
                    TextWidget(
                      text:
                          'P${(data['total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                      fontSize: 14,
                      fontFamily: 'Bold',
                      color: Colors.grey[800],
                    ),
                  ],
                ),
                // Only show action buttons for Ready to Pickup orders

                // Show "Tap to view" hint for pending, preparing, and ready orders
                if (status == 'Pending')
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        TextWidget(
                          text: 'Tap to view details',
                          fontSize: 11,
                          fontFamily: 'Medium',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  )
                else if (status == 'Accepted')
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Colors.blue,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        TextWidget(
                          text: 'Tap to view details',
                          fontSize: 11,
                          fontFamily: 'Medium',
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  )
                else if (status == 'Ready to Pickup')
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        TextWidget(
                          text: 'Tap to view details',
                          fontSize: 11,
                          fontFamily: 'Medium',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build status count card widget
  Widget _buildStatusCountCard(String title, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        TextWidget(
          text: title,
          fontSize: 11,
          fontFamily: 'Medium',
          color: Colors.grey[700],
        ),
        const SizedBox(height: 3),
      ],
    );
  }

  // Build customization details widget
  Widget _buildCustomizationDetails(Map<String, dynamic> customizations) {
    List<Widget> customizationWidgets = [];

    customizations.forEach((key, value) {
      if (value != null) {
        String displayText = '';
        switch (key) {
          case 'espresso':
            displayText = 'Espresso: $value';
            break;
          case 'addShot':
            displayText = 'Extra Shot: ${value ? 'Yes' : 'No'}';
            break;
          case 'size':
            displayText = 'Size: $value';
            break;
          case 'sweetness':
            displayText = 'Sweetness: $value';
            break;
          case 'ice':
            displayText = 'Ice: $value';
            break;
          default:
            displayText = '$key: $value';
        }

        customizationWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_right,
                  size: 12,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextWidget(
                    text: displayText,
                    fontSize: 11,
                    fontFamily: 'Regular',
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: customizationWidgets,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
