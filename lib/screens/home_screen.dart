import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/utils/branch_service.dart';
import 'package:kaffi_cafe_pos/utils/role_service.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/textfield_widget.dart';
import 'package:kaffi_cafe_pos/widgets/touchable_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kaffi_cafe_pos/screens/staff_screen.dart';
import 'package:kaffi_cafe_pos/screens/notification_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _searchQuery = '';
  final List<Map<String, dynamic>> _cartItems = [];
  double _subtotal = 0.0;
  double _change = 0.0;
  bool _isLoggedIn = false;
  String _currentStaffName = '';
  String? _currentBranch;
  String _selectedPaymentMethod = 'Cash';

  final List<String> categories = [
    'All',
    'Coffee',
    'Non-Coffee Drinks',
    'Pastries',
    'Sandwiches',
    'Frappe',
    'Cloud Series',
    'Milk Tea',
    'Fruit Tea',
    'Croffle',
    'Pasta',
    'Add-ons'
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_staff_logged_in') ?? false;
    final staffName = prefs.getString('current_staff_name') ?? '';
    final currentBranch = BranchService.getSelectedBranch();

    // Check if branch is selected
    if (currentBranch == null) {
      // Redirect to branch selection screen if no branch is selected
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/branch');
      }
      return;
    }

    if (!isLoggedIn) {
      // Redirect to staff login screen if not logged in
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StaffScreen()),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = true;
        _currentStaffName = staffName;
        _currentBranch = currentBranch;
      });

      _tabController = TabController(length: categories.length, vsync: this);
      _searchController.addListener(() {
        setState(() {
          _searchQuery = _searchController.text;
        });
      });
      _amountController.addListener(_calculateChange);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _addToCart(Map<String, dynamic> product) {
    _showCustomizationDialog(product);
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
      _calculateSubtotal();
      _calculateChange();
    });
  }

  void _calculateSubtotal() {
    _subtotal = _cartItems.fold(
        0.0,
        (sum, item) =>
            sum + (item['totalPrice'] ?? item['price']) * item['quantity']);
  }

  void _calculateChange() {
    final amountPaid = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _change = amountPaid - _subtotal;
    });
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Cash'),
              leading: Radio<String>(
                value: 'Cash',
                groupValue: _selectedPaymentMethod,
                onChanged: (String? value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                  Navigator.pop(context);
                  _completePayment('Cash');
                },
              ),
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = 'Cash';
                });
                Navigator.pop(context);
                _completePayment('Cash');
              },
            ),
            ListTile(
              title: const Text('GCash'),
              leading: Radio<String>(
                value: 'GCash',
                groupValue: _selectedPaymentMethod,
                onChanged: (String? value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                  Navigator.pop(context);
                  _completePayment('GCash');
                },
              ),
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = 'GCash';
                });
                Navigator.pop(context);
                _completePayment('GCash');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCustomizationDialog(Map<String, dynamic> product) {
    int quantity = 1;
    String selectedEspresso = 'Standard (double)';
    bool addShot = false;
    String selectedSize = 'Regular';
    String selectedSweetness = 'Regular Sweetness';
    String selectedIce = 'Regular';

    final List<String> espressoOptions = [
      'Standard (double)',
    ];

    final List<String> sizeOptions = [
      'Regular',
      'Large',
    ];

    final List<String> sweetnessLevels = [
      'Regular Sweetness',
      'Less Sweet',
      'Extra Sweet',
    ];

    final List<String> iceLevels = [
      'Regular',
      'Less Ice',
    ];

    double calculateTotalPrice() {
      double basePrice = product['price'].toDouble();
      double addShotPrice = addShot ? 25.0 : 0.0;
      double sizePrice = selectedSize == 'Large' ? 15.0 : 0.0;
      return basePrice + addShotPrice + sizePrice;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double totalPrice = calculateTotalPrice();

            return AlertDialog(
              title: Text('Customize ${product['name']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quantity
                    Row(
                      children: [
                        const Text('Quantity:'),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (quantity > 1) {
                              setState(() => quantity--);
                            }
                          },
                        ),
                        Text(quantity.toString()),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() => quantity++);
                          },
                        ),
                      ],
                    ),

                    // Espresso Options
                    if (product['category'] == 'Coffee') ...[
                      const SizedBox(height: 16),
                      const Text('Espresso:'),
                      DropdownButton<String>(
                        value: selectedEspresso,
                        isExpanded: true,
                        items: espressoOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() => selectedEspresso = newValue!);
                        },
                      ),
                    ],

                    // Size Options
                    const SizedBox(height: 16),
                    const Text('Size:'),
                    DropdownButton<String>(
                      value: selectedSize,
                      isExpanded: true,
                      items: sizeOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() => selectedSize = newValue!);
                      },
                    ),

                    // Sweetness Level
                    const SizedBox(height: 16),
                    const Text('Sweetness Level:'),
                    DropdownButton<String>(
                      value: selectedSweetness,
                      isExpanded: true,
                      items: sweetnessLevels.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() => selectedSweetness = newValue!);
                      },
                    ),

                    // Ice Level
                    const SizedBox(height: 16),
                    const Text('Ice Level:'),
                    DropdownButton<String>(
                      value: selectedIce,
                      isExpanded: true,
                      items: iceLevels.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() => selectedIce = newValue!);
                      },
                    ),

                    // Add Shot
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Add Extra Shot (+₱25)'),
                        const Spacer(),
                        Switch(
                          value: addShot,
                          onChanged: (bool value) {
                            setState(() => addShot = value);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Price:'),
                        Text(
                          '₱${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      final customization = {
                        'name': product['name'],
                        'price': product['price'],
                        'totalPrice': totalPrice,
                        'quantity': quantity,
                        'docId': product['docId'],
                        'customizations': {
                          'espresso': selectedEspresso,
                          'size': selectedSize,
                          'sweetness': selectedSweetness,
                          'ice': selectedIce,
                          'addShot': addShot,
                        },
                      };

                      final existingItemIndex = _cartItems.indexWhere((item) =>
                          item['name'] == product['name'] &&
                          item['customizations']?['espresso'] ==
                              selectedEspresso &&
                          item['customizations']?['size'] == selectedSize &&
                          item['customizations']?['sweetness'] ==
                              selectedSweetness &&
                          item['customizations']?['ice'] == selectedIce &&
                          item['customizations']?['addShot'] == addShot);

                      if (existingItemIndex != -1) {
                        _cartItems[existingItemIndex]['quantity'] += quantity;
                      } else {
                        _cartItems.add(customization);
                      }

                      _calculateSubtotal();
                      _calculateChange();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Add to Cart'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processPayment() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Cart is empty',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }
    if (_amountController.text.isEmpty || _change < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Insufficient amount paid',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    // Show payment method selection
    _showPaymentMethodDialog();
  }

  Future<void> _completePayment(String selectedPaymentMethod) async {
    try {
      // Since we removed stock tracking, we don't need to check or update stock
      final orderId =
          (await _firestore.collection('orders').get()).docs.length + 1001;

      // Create order data for the dialog
      final orderData = {
        'orderId': orderId.toString(),
        'timestamp': DateTime.now(),
        'items': _cartItems
            .map((item) => {
                  'name': item['name'],
                  'quantity': item['quantity'],
                  'price': item['price'],
                  'totalPrice': item['totalPrice'] ?? item['price'],
                  'customizations': item['customizations'],
                })
            .toList(),
        'subtotal': _subtotal,
        'total': _subtotal,
        'amountPaid': double.tryParse(_amountController.text) ?? 0.0,
        'change': _change,
      };

      if (selectedPaymentMethod == 'GCash') {
        // For GCash payments, simulate the payment process
        // In a real implementation, you would integrate with PayMongo
        await _processGCashPayment(orderData);
      } else {
        // For Cash payments, proceed directly
        await _firestore.collection('orders').add({
          'orderId': orderId.toString(),
          'buyer': 'Cashier',
          'items': _cartItems
              .map((item) => {
                    'name': item['name'],
                    'quantity': item['quantity'],
                    'price': item['price'],
                    'totalPrice': item['totalPrice'] ?? item['price'],
                    'customizations': item['customizations'],
                  })
              .toList(),
          'total': _subtotal,
          'status': 'Accepted',
          'timestamp': FieldValue.serverTimestamp(),
          'type': '',
          'branch': _currentBranch,
          'paymentMethod': selectedPaymentMethod,
        });
        setState(() {
          _cartItems.clear();
          _subtotal = 0.0;
          _change = 0.0;
          _amountController.clear();
        });

        // Show payment success dialog with order data
        _showPaymentSuccessDialog(orderData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error processing payment: $e',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  Future<void> _processGCashPayment(Map<String, dynamic> orderData) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Processing GCash payment...'),
            ],
          ),
        ),
      );

      // Simulate GCash payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // For actual PayMongo integration, you would:
      // 1. Create a payment source with PayMongo
      // 2. Get the checkout URL
      // 3. Launch the URL for customer payment
      // 4. Handle the payment callback

      // For now, simulate successful GCash payment
      final orderId =
          (await _firestore.collection('orders').get()).docs.length + 1001;

      await _firestore.collection('orders').add({
        'orderId': orderId.toString(),
        'buyer': 'Cashier',
        'items': _cartItems
            .map((item) => {
                  'name': item['name'],
                  'quantity': item['quantity'],
                  'price': item['price'],
                  'totalPrice': item['totalPrice'] ?? item['price'],
                  'customizations': item['customizations'],
                })
            .toList(),
        'total': _subtotal,
        'status': 'Accepted',
        'timestamp': FieldValue.serverTimestamp(),
        'type': '',
        'branch': _currentBranch,
        'paymentMethod': _selectedPaymentMethod,
        'paymentStatus': 'Paid',
      });

      setState(() {
        _cartItems.clear();
        _subtotal = 0.0;
        _change = 0.0;
        _amountController.clear();
      });

      if (context.mounted) {
        _showPaymentSuccessDialog(orderData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GCash payment processed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GCash payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(orderData['timestamp'])}',
                  style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Branch: ${_currentBranch ?? ''}',
                  style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Payment: $_selectedPaymentMethod',
                  style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text('Items:',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              ...orderData['items'].map<pw.Widget>((item) => pw.Padding(
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
                              'P${((item['totalPrice'] ?? item['price']) * item['quantity']).toStringAsFixed(2)}',
                              style: const pw.TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  )),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 14)),
                  pw.Text('P${orderData['subtotal'].toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
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

  // Generate receipt PDF
  Future<pw.Document> _generateReceiptPdf(
      Map<String, dynamic> orderData) async {
    final pdf = pw.Document();

    // Get current staff name
    final staffName = await _getCurrentStaffName();
    final isAdmin = await RoleService.isSuperAdmin();

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
                  'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(orderData['timestamp'])}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Branch: ${_currentBranch ?? ''}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Payment: $_selectedPaymentMethod',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 15),
              pw.Divider(),
              ...orderData['items'].map<pw.Widget>((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text('${item['name']} x${item['quantity']}',
                              style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Text(
                            'P${((item['totalPrice'] ?? item['price']) * item['quantity']).toStringAsFixed(2)}',
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
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Amount Paid:',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('P${orderData['amountPaid'].toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Change:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('P${orderData['change'].toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 10)),
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
                      text: 'Payment Successful',
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
                      text:
                          'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(orderData['timestamp'])}',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text: 'Branch: ${_currentBranch ?? ''}',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text: 'Payment: $_selectedPaymentMethod',
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
                          children: orderData['items'].map<Widget>((item) {
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
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextWidget(
                                text: 'Subtotal:',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.grey[700],
                              ),
                              TextWidget(
                                text:
                                    'P${orderData['subtotal'].toStringAsFixed(2)}',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.grey[800],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextWidget(
                                text: 'Total:',
                                fontSize: 16,
                                fontFamily: 'Bold',
                                color: Colors.grey[800],
                              ),
                              TextWidget(
                                text:
                                    'P${orderData['total'].toStringAsFixed(2)}',
                                fontSize: 16,
                                fontFamily: 'Bold',
                                color: Colors.grey[800],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextWidget(
                                text: 'Amount Paid:',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.grey[700],
                              ),
                              TextWidget(
                                text:
                                    'P${orderData['amountPaid'].toStringAsFixed(2)}',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.grey[800],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextWidget(
                                text: 'Change:',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.grey[700],
                              ),
                              TextWidget(
                                text:
                                    'P${orderData['change'].toStringAsFixed(2)}',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: orderData['change'] >= 0
                                    ? Colors.green[600]!
                                    : Colors.red[600]!,
                              ),
                            ],
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Coffee':
        return Icons.local_cafe;
      case 'Non-Coffee Drinks':
        return Icons.local_bar;
      case 'Pastries':
        return Icons.cake;
      case 'Sandwiches':
        return Icons.lunch_dining;
      case 'Add-ons':
        return Icons.add_shopping_cart;
      case 'Frappe':
        return Icons.local_cafe;
      case 'Cloud Series':
        return Icons.local_bar;
      case 'Milk Tea':
        return Icons.local_cafe;
      case 'Fruit Tea':
        return Icons.local_cafe;
      case 'Croffle':
        return Icons.cake;
      case 'Pasta':
        return Icons.lunch_dining;
      default:
        return Icons.fastfood;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      // Show a loading indicator while checking login status
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('orders')
                  .where('branch', isEqualTo: _currentBranch)
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
                final orders = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final orderId =
                      data['orderId']?.toString().toLowerCase() ?? '';
                  final buyer = data['buyer']?.toString().toLowerCase() ?? '';
                  return orderId.contains(_searchQuery) ||
                      buyer.contains(_searchQuery);
                }).where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status']?.toString() ?? '';
                  return status == 'Pending';
                }).toList();
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Badge(
                      label: TextWidget(
                        text: orders.length.toString(),
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      child: Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                );
              }),
        ],
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextWidget(
              text: 'Register',
              fontSize: 18,
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
                  hintText: 'Search items...',
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
            const SizedBox(width: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  TextWidget(
                    text: _currentStaffName,
                    fontSize: 14,
                    fontFamily: 'Medium',
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontFamily: 'Medium',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Regular',
            fontSize: 16,
          ),
          tabs: categories
              .map((cat) => Tab(
                    child: TextWidget(
                      text: cat,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ))
              .toList(),
        ),
      ),
      drawer: const DrawerWidget(),
      body: TabBarView(
        controller: _tabController,
        children: categories.map((category) {
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('products')
                .where('branch', isEqualTo: _currentBranch)
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
              final products = snapshot.data!.docs;
              // Filter products by category and search query
              final filteredProducts = products.where((product) {
                final data = product.data() as Map<String, dynamic>;
                final productName =
                    (data['name'] as String?)?.toLowerCase() ?? '';
                final productCategory = data['category'] as String? ?? '';

                // If "All" category is selected, show all products
                // Otherwise, filter by specific category
                if (category != 'All' && productCategory != category)
                  return false;

                // If searching, also filter by name
                if (_searchQuery.isNotEmpty) {
                  return productName.contains(_searchQuery.toLowerCase());
                }

                return true;
              }).toList();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: filteredProducts.isEmpty && _searchQuery.isNotEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  TextWidget(
                                    text:
                                        'No products found for "$_searchQuery"',
                                    fontSize: 18,
                                    fontFamily: 'Medium',
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  TextWidget(
                                    text: 'Try a different search term',
                                    fontSize: 14,
                                    fontFamily: 'Regular',
                                    color: Colors.grey[500],
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final data =
                                    product.data() as Map<String, dynamic>;
                                return TouchableWidget(
                                  onTap: () => _addToCart({
                                    'name': data['name'] ?? 'Unnamed',
                                    'price':
                                        (data['price'] as num?)?.toDouble() ??
                                            0.0,
                                    'category': data['category'] ?? 'Foods',
                                    'docId': product.id,
                                  }),
                                  child: Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          data['image'] != null &&
                                                  data['image'] != ''
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.network(
                                                    data['image'],
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return CircleAvatar(
                                                        radius: 30,
                                                        backgroundColor:
                                                            AppTheme
                                                                .primaryColor
                                                                .withOpacity(
                                                                    0.1),
                                                        child: Icon(
                                                          _getCategoryIcon(data[
                                                                  'category'] ??
                                                              'Foods'),
                                                          size: 40,
                                                          color: AppTheme
                                                              .primaryColor,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : CircleAvatar(
                                                  radius: 30,
                                                  backgroundColor: AppTheme
                                                      .primaryColor
                                                      .withOpacity(0.1),
                                                  child: Icon(
                                                    _getCategoryIcon(
                                                        data['category'] ??
                                                            'Foods'),
                                                    size: 40,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                ),
                                          const SizedBox(height: 12),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 5, right: 5),
                                            child: TextWidget(
                                              align: TextAlign.center,
                                              text: data['name'] ?? 'Unnamed',
                                              fontSize: 16,
                                              fontFamily: 'Medium',
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          TextWidget(
                                            text:
                                                'P${(data['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                            fontSize: 14,
                                            fontFamily: 'Regular',
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  Container(
                    width: 360,
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 180,
                                child: ListView.builder(
                                  itemCount: _cartItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _cartItems[index];
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 6.0),
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.grey[200]!),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[100],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: TextWidget(
                                              text: 'x${item['quantity']}',
                                              fontSize: 16,
                                              fontFamily: 'Bold',
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                TextWidget(
                                                  text: item['name'],
                                                  fontSize: 16,
                                                  fontFamily: 'Medium',
                                                  color: Colors.grey[800],
                                                ),
                                                if (item['customizations'] !=
                                                    null) ...[
                                                  TextWidget(
                                                    text:
                                                        '${item['customizations']['size']}, ${item['customizations']['sweetness']}, ${item['customizations']['ice']}',
                                                    fontSize: 12,
                                                    fontFamily: 'Regular',
                                                    color: Colors.grey[600],
                                                  ),
                                                  if (item['customizations']
                                                          ['addShot'] ==
                                                      true)
                                                    TextWidget(
                                                      text: '+ Extra Shot',
                                                      fontSize: 12,
                                                      fontFamily: 'Regular',
                                                      color: Colors.blue[600],
                                                    ),
                                                ],
                                                TextWidget(
                                                  text:
                                                      'P${(item['totalPrice'] ?? item['price'] as num).toStringAsFixed(2)}',
                                                  fontSize: 14,
                                                  fontFamily: 'Regular',
                                                  color: Colors.grey[600],
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                _removeFromCart(index),
                                            icon: Icon(
                                              Icons.delete_forever,
                                              color: Colors.red[400],
                                              size: 28,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextFieldWidget(
                                  label: 'Enter Amount Paid',
                                  controller: _amountController,
                                  inputType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Divider(color: Colors.grey[300], thickness: 1.5),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextWidget(
                                    text: 'Subtotal',
                                    fontSize: 18,
                                    fontFamily: 'Bold',
                                    color: Colors.grey[800],
                                  ),
                                  TextWidget(
                                    text: 'P${_subtotal.toStringAsFixed(2)}',
                                    fontSize: 18,
                                    fontFamily: 'Bold',
                                    color: Colors.grey[800],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextWidget(
                                    text: 'Change',
                                    fontSize: 16,
                                    fontFamily: 'Medium',
                                    color: Colors.grey[600],
                                  ),
                                  TextWidget(
                                    text: _change >= 0
                                        ? 'P${_change.toStringAsFixed(2)}'
                                        : 'P0.00',
                                    fontSize: 16,
                                    fontFamily: 'Medium',
                                    color: _change >= 0
                                        ? Colors.green[600]
                                        : Colors.red[600],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Divider(color: Colors.grey[300], thickness: 1.5),
                              const SizedBox(height: 20),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextWidget(
                                      text: 'Payment Method:',
                                      fontSize: 14,
                                      fontFamily: 'Medium',
                                      color: Colors.grey[700],
                                    ),
                                    TextWidget(
                                      text: _selectedPaymentMethod,
                                      fontSize: 14,
                                      fontFamily: 'Bold',
                                      color: AppTheme.primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: ButtonWidget(
                                  radius: 12,
                                  color: Colors.green[600]!,
                                  textColor: Colors.white,
                                  label: 'Process Payment',
                                  onPressed: _processPayment,
                                  fontSize: 18,
                                  width: 240,
                                  height: 56,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
