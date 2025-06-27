import 'package:flutter/material.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _selectedCategory = 'All'; // Default category

  // Sample product data with categories
  final List<Map<String, dynamic>> _products = [
    {'name': 'Espresso', 'stock': 50, 'price': 120.0, 'category': 'Coffee'},
    {'name': 'Latte', 'stock': 30, 'price': 150.0, 'category': 'Coffee'},
    {'name': 'Iced Tea', 'stock': 20, 'price': 100.0, 'category': 'Drinks'},
    {'name': 'Orange Juice', 'stock': 15, 'price': 110.0, 'category': 'Drinks'},
    {'name': 'Croissant', 'stock': 40, 'price': 80.0, 'category': 'Foods'},
    {'name': 'Sandwich', 'stock': 25, 'price': 200.0, 'category': 'Foods'},
  ];

  // Filter products by category
  List<Map<String, dynamic>> _filteredProducts() {
    if (_selectedCategory == 'All') return _products;
    return _products
        .where((product) => product['category'] == _selectedCategory)
        .toList();
  }

  // Dialog for updating ingredient details
  void _showUpdateIngredientDialog(
      BuildContext context, String ingredientName, double quantity) {
    final nameController = TextEditingController(text: ingredientName);
    final quantityController = TextEditingController(text: quantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: TextWidget(
          text: 'Update Ingredient',
          fontSize: 18,
          fontFamily: 'Bold',
          color: Colors.grey[800],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Ingredient Name',
                labelStyle: TextStyle(color: Colors.grey[600]),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity (kg)',
                labelStyle: TextStyle(color: Colors.grey[600]),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
              ),
            ),
          ],
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
            onPressed: () {
              // Implement update logic here
              print(
                  'Ingredient Updated: ${nameController.text}, ${quantityController.text} kg');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: TextWidget(
              text: 'Update',
              fontSize: 14,
              fontFamily: 'Medium',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Dialog for updating menu product details
  void _showUpdateProductDialog(BuildContext context, String productName,
      int stock, double price, String category) {
    final nameController = TextEditingController(text: productName);
    final stockController = TextEditingController(text: stock.toString());
    final priceController = TextEditingController(text: price.toString());
    String selectedCategory = category.isEmpty ? 'Coffee' : category;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: TextWidget(
          text: 'Update Product',
          fontSize: 18,
          fontFamily: 'Bold',
          color: Colors.grey[800],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryBlue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryBlue, width: 2),
                  ),
                ),
                items: ['Coffee', 'Drinks', 'Foods'].map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: TextWidget(
                      text: category,
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.black87,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Stock (units)',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryBlue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (P)',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryBlue, width: 2),
                  ),
                ),
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
            onPressed: () {
              if (nameController.text.isEmpty ||
                  stockController.text.isEmpty ||
                  priceController.text.isEmpty) {
                return;
              }
              // Implement update logic here
              print('Product Updated: ${nameController.text}, '
                  'Category: $selectedCategory, '
                  'Stock: ${stockController.text}, '
                  'Price: ${priceController.text}');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: TextWidget(
              text: 'Update',
              fontSize: 14,
              fontFamily: 'Medium',
              color: Colors.white,
            ),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextWidget(
              text: 'Inventory',
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
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  hintText: 'Search inventory...',
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
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Raw Ingredients Section
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                        text: 'Raw Ingredients',
                        fontSize: 20,
                        fontFamily: 'Bold',
                        color: Colors.grey[800],
                      ),
                      ButtonWidget(
                        radius: 12,
                        color: primaryBlue,
                        textColor: Colors.white,
                        label: 'Add Ingredient',
                        onPressed: () {
                          _showUpdateIngredientDialog(context, '', 0.0);
                        },
                        fontSize: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 3, // Sample ingredient count
                      itemBuilder: (context, index) {
                        final isLowStock =
                            index == 0; // Example condition for low stock
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isLowStock
                                      ? Colors.red[100]!
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          TextWidget(
                                            text: 'Coffee Beans',
                                            fontSize: 18,
                                            fontFamily: 'Medium',
                                            color: Colors.grey[800],
                                          ),
                                          if (isLowStock) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: TextWidget(
                                                text: 'Low Stock',
                                                fontSize: 12,
                                                fontFamily: 'Regular',
                                                color: Colors.red[600],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      TextWidget(
                                        text: 'Quantity: 5 kg',
                                        fontSize: 14,
                                        fontFamily: 'Regular',
                                        color: Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          _showUpdateIngredientDialog(
                                              context, 'Coffee Beans', 5.0);
                                        },
                                        icon: Icon(
                                          Icons.edit,
                                          color: primaryBlue,
                                          size: 26,
                                        ),
                                        tooltip: 'Update Ingredient',
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          // Delete ingredient logic
                                        },
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red[400],
                                          size: 26,
                                        ),
                                        tooltip: 'Delete Ingredient',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Menu Products Section
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                        text: 'Menu Products',
                        fontSize: 20,
                        fontFamily: 'Bold',
                        color: Colors.grey[800],
                      ),
                      ButtonWidget(
                        radius: 12,
                        color: primaryBlue,
                        textColor: Colors.white,
                        label: 'Add Product',
                        onPressed: () {
                          _showUpdateProductDialog(context, '', 0, 0.0, '');
                        },
                        fontSize: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryButton('All'),
                        _buildCategoryButton('Coffee'),
                        _buildCategoryButton('Drinks'),
                        _buildCategoryButton('Foods'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredProducts().length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts()[index];
                        final isLowStock = product['stock'] <
                            20; // Example low stock threshold
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isLowStock
                                      ? Colors.red[100]!
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          TextWidget(
                                            text: product['name'],
                                            fontSize: 18,
                                            fontFamily: 'Medium',
                                            color: Colors.grey[800],
                                          ),
                                          if (isLowStock) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: TextWidget(
                                                text: 'Low Stock',
                                                fontSize: 12,
                                                fontFamily: 'Regular',
                                                color: Colors.red[600],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      TextWidget(
                                        text:
                                            'Category: ${product['category']}',
                                        fontSize: 14,
                                        fontFamily: 'Regular',
                                        color: Colors.grey[600],
                                      ),
                                      TextWidget(
                                        text:
                                            'Stock: ${product['stock']} units',
                                        fontSize: 14,
                                        fontFamily: 'Regular',
                                        color: Colors.grey[600],
                                      ),
                                      TextWidget(
                                        text:
                                            'Price: P${product['price'].toStringAsFixed(2)}',
                                        fontSize: 14,
                                        fontFamily: 'Regular',
                                        color: Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          _showUpdateProductDialog(
                                            context,
                                            product['name'],
                                            product['stock'],
                                            product['price'],
                                            product['category'],
                                          );
                                        },
                                        icon: Icon(
                                          Icons.edit,
                                          color: primaryBlue,
                                          size: 26,
                                        ),
                                        tooltip: 'Update Product',
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          // Delete product logic
                                        },
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red[400],
                                          size: 26,
                                        ),
                                        tooltip: 'Delete Product',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ButtonWidget(
        width: 150,
        radius: 12,
        color: isSelected ? primaryBlue : Colors.grey[200]!,
        textColor: isSelected ? Colors.white : Colors.grey[800],
        label: category,
        onPressed: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        fontSize: 14,
      ),
    );
  }
}
