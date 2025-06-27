import 'package:flutter/material.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
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

  final List<String> categories = [
    'Coffee',
    'Drinks',
    'Foods',
  ];

  // Sample product data with categories
  final List<Map<String, dynamic>> _products = [
    {'name': 'Espresso', 'price': 120.0, 'category': 'Coffee'},
    {'name': 'Latte', 'price': 150.0, 'category': 'Coffee'},
    {'name': 'Iced Tea', 'price': 100.0, 'category': 'Drinks'},
    {'name': 'Orange Juice', 'price': 110.0, 'category': 'Drinks'},
    {'name': 'Croissant', 'price': 80.0, 'category': 'Foods'},
    {'name': 'Sandwich', 'price': 200.0, 'category': 'Foods'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final amount = TextEditingController();

  // Get icon for category
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
        backgroundColor: primaryBlue,
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
          final filteredProducts = _products
              .where((product) => product['category'] == category)
              .toList();
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
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
                      return TouchableWidget(
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: primaryBlue.withOpacity(0.1),
                                  child: Icon(
                                    _getCategoryIcon(product['category']),
                                    size: 40,
                                    color: primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextWidget(
                                  text: product['name'],
                                  fontSize: 16,
                                  fontFamily: 'Medium',
                                  color: Colors.grey[800],
                                ),
                                TextWidget(
                                  text:
                                      'P${product['price'].toStringAsFixed(2)}',
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
                              itemCount: 2,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: Colors.grey[200]!),
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
                                          text: 'x2',
                                          fontSize: 16,
                                          fontFamily: 'Bold',
                                          color: primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TextWidget(
                                              text: 'Caramel Macchiato',
                                              fontSize: 16,
                                              fontFamily: 'Medium',
                                              color: Colors.grey[800],
                                            ),
                                            TextWidget(
                                              text: 'P150.00',
                                              fontSize: 14,
                                              fontFamily: 'Regular',
                                              color: Colors.grey[600],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {},
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
                              controller: amount,
                              inputType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Divider(color: Colors.grey[300], thickness: 1.5),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextWidget(
                                text: 'Subtotal',
                                fontSize: 18,
                                fontFamily: 'Bold',
                                color: Colors.grey[800],
                              ),
                              TextWidget(
                                text: 'P300.00',
                                fontSize: 18,
                                fontFamily: 'Bold',
                                color: Colors.grey[800],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextWidget(
                                text: 'Change',
                                fontSize: 16,
                                fontFamily: 'Medium',
                                color: Colors.grey[600],
                              ),
                              TextWidget(
                                text: 'P200.00',
                                fontSize: 16,
                                fontFamily: 'Medium',
                                color: Colors.green[600],
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
                              onPressed: () {},
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
        }).toList(),
      ),
    );
  }
}
