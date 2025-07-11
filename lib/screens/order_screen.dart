import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  // Dialog for adding a new order
  void _showAddOrderDialog(BuildContext context) {
    final buyerController = TextEditingController();
    final itemNameController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final List<Map<String, dynamic>> items = [];

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
                    borderSide: BorderSide(color: bayanihanBlue, width: 2),
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
                    borderSide: BorderSide(color: bayanihanBlue, width: 2),
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
                    borderSide: BorderSide(color: bayanihanBlue, width: 2),
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
                    borderSide: BorderSide(color: bayanihanBlue, width: 2),
                  ),
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
                      backgroundColor: bayanihanBlue,
                    ),
                  );
                },
                color: bayanihanBlue,
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
                    backgroundColor: bayanihanBlue,
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
              backgroundColor: bayanihanBlue,
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

  // Update order status
  Future<void> _updateOrderStatus(String docId, String status) async {
    try {
      await _firestore.collection('orders').doc(docId).update({
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Order $status successfully',
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

  // Delete order
  Future<void> _deleteOrder(String docId) async {
    try {
      await _firestore.collection('orders').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Order deleted successfully',
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
            text: 'Error deleting order: $e',
            fontSize: 14,
            fontFamily: 'Regular',
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
        backgroundColor: bayanihanBlue,
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
            textColor: bayanihanBlue,
            fontSize: 14,
            radius: 10,
            height: 40,
            width: 120,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('orders')
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
            final orders = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final orderId = data['orderId']?.toString().toLowerCase() ?? '';
              final buyer = data['buyer']?.toString().toLowerCase() ?? '';
              return orderId.contains(_searchQuery) ||
                  buyer.contains(_searchQuery);
            }).toList();
            return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final data = order.data() as Map<String, dynamic>;
                  final items = (data['items'] as List<dynamic>?)
                          ?.cast<Map<String, dynamic>>() ??
                      [];
                  final status = data['status'] ?? 'Pending';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextWidget(
                                  text: 'Order #${data['orderId'] ?? 'N/A'}',
                                  fontSize: 18,
                                  fontFamily: 'Bold',
                                  color: Colors.grey[800],
                                ),
                                TextWidget(
                                  text: status,
                                  fontSize: 14,
                                  fontFamily: 'Medium',
                                  color: status == 'Accepted'
                                      ? Colors.green[600]
                                      : status == 'Declined'
                                          ? Colors.red[600]
                                          : Colors.orange[600],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextWidget(
                              text: 'Buyer: ${data['buyer'] ?? 'Unknown'}',
                              fontSize: 16,
                              fontFamily: 'Medium',
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.grey, thickness: 0.5),
                            const SizedBox(height: 12),
                            // Order Items
                            Column(
                              children: items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
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
                                          text: 'x${item['quantity'] ?? 1}',
                                          fontSize: 14,
                                          fontFamily: 'Bold',
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextWidget(
                                          text: item['name'] ?? 'Unknown Item',
                                          fontSize: 16,
                                          fontFamily: 'Regular',
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      TextWidget(
                                        text:
                                            'P${(item['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                        fontSize: 14,
                                        fontFamily: 'Regular',
                                        color: Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.grey, thickness: 0.5),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextWidget(
                                  text: 'Total',
                                  fontSize: 16,
                                  fontFamily: 'Bold',
                                  color: Colors.grey[800],
                                ),
                                TextWidget(
                                  text:
                                      'P${(data['total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                  fontSize: 16,
                                  fontFamily: 'Bold',
                                  color: Colors.grey[800],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () => _deleteOrder(order.id),
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red[400],
                                    size: 26,
                                  ),
                                  tooltip: 'Delete Order',
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: status == 'Pending'
                                      ? () => _updateOrderStatus(
                                          order.id, 'Declined')
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[400],
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(120, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: TextWidget(
                                    text: 'Decline',
                                    fontSize: 16,
                                    fontFamily: 'Medium',
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: status == 'Pending'
                                      ? () => _updateOrderStatus(
                                          order.id, 'Accepted')
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(120, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: TextWidget(
                                    text: 'Accept',
                                    fontSize: 16,
                                    fontFamily: 'Medium',
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
