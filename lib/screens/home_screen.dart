import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/textfield_widget.dart';
import 'package:kaffi_cafe_pos/widgets/touchable_widget.dart';

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

  final List<String> categories = ['Coffee', 'Drinks', 'Foods'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _amountController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final existingItemIndex =
          _cartItems.indexWhere((item) => item['name'] == product['name']);
      if (existingItemIndex != -1) {
        _cartItems[existingItemIndex]['quantity'] += 1;
      } else {
        _cartItems.add({
          'name': product['name'],
          'price': product['price'],
          'quantity': 1,
          'docId': product['docId'],
        });
      }
      _calculateSubtotal();
    });
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
        0.0, (sum, item) => sum + item['price'] * item['quantity']);
  }

  void _calculateChange() {
    final amountPaid = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _change = amountPaid - _subtotal;
    });
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
    try {
      final batch = _firestore.batch();
      for (var item in _cartItems) {
        final productRef = _firestore.collection('products').doc(item['docId']);
        final productDoc = await productRef.get();
        final currentStock =
            (productDoc.data()?['stock'] as num?)?.toInt() ?? 0;
        if (currentStock < item['quantity']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: TextWidget(
                text: 'Insufficient stock for ${item['name']}',
                fontSize: 14,
                fontFamily: 'Regular',
                color: Colors.white,
              ),
              backgroundColor: Colors.red[600],
            ),
          );
          return;
        }
        batch.update(productRef, {
          'stock': currentStock - item['quantity'],
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
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
                })
            .toList(),
        'total': _subtotal,
        'status': 'Accepted',
        'timestamp': FieldValue.serverTimestamp(),
        'type': '',
        'branch': ''
      });
      await batch.commit();
      setState(() {
        _cartItems.clear();
        _subtotal = 0.0;
        _change = 0.0;
        _amountController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Payment processed successfully',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: Colors.green[600],
        ),
      );
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Coffee':
        return Icons.local_cafe;
      case 'Drinks':
        return Icons.local_drink;
      case 'Foods':
        return Icons.fastfood;
      default:
        return Icons.fastfood;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
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

                // Always filter by category
                if (productCategory != category) return false;

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
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor: AppTheme
                                                .primaryColor
                                                .withOpacity(0.1),
                                            child: Icon(
                                              _getCategoryIcon(
                                                  data['category'] ?? 'Foods'),
                                              size: 40,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          TextWidget(
                                            text: data['name'] ?? 'Unnamed',
                                            fontSize: 16,
                                            fontFamily: 'Medium',
                                            color: Colors.grey[800],
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
                                                TextWidget(
                                                  text:
                                                      'P${(item['price'] as num).toStringAsFixed(2)}',
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
