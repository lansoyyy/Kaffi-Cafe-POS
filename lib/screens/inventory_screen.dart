import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _selectedCategory = 'All';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  void _showUpdateIngredientDialog(BuildContext context, String? docId,
      String ingredientName, double quantity) {
    final nameController = TextEditingController(text: ingredientName);
    final quantityController = TextEditingController(text: quantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: TextWidget(
          text: docId == null ? 'Add Ingredient' : 'Update Ingredient',
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
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
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
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
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
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  quantityController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Please fill in all fields',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.white,
                    ),
                    backgroundColor: Colors.red[600],
                  ),
                );
                return;
              }
              final quantity = double.tryParse(quantityController.text);
              if (quantity == null || quantity < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Invalid quantity',
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
                final data = {
                  'name': nameController.text,
                  'searchName': nameController.text.toLowerCase(),
                  'quantity': quantity,
                  'timestamp': FieldValue.serverTimestamp(),
                };
                if (docId == null) {
                  await _firestore.collection('ingredients').add(data);
                } else {
                  await _firestore
                      .collection('ingredients')
                      .doc(docId)
                      .update(data);
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Error: $e',
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
              text: docId == null ? 'Add' : 'Update',
              fontSize: 14,
              fontFamily: 'Medium',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateProductDialog(BuildContext context, String? docId,
      String productName, int stock, double price, String category) {
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
          text: docId == null ? 'Add Product' : 'Update Product',
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
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
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
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
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
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
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
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
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
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  stockController.text.isEmpty ||
                  priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Please fill in all fields',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.white,
                    ),
                    backgroundColor: Colors.red[600],
                  ),
                );
                return;
              }
              final stock = int.tryParse(stockController.text);
              final price = double.tryParse(priceController.text);
              if (stock == null || stock < 0 || price == null || price < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Invalid stock or price',
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
                final data = {
                  'name': nameController.text,
                  'searchName': nameController.text.toLowerCase(),
                  'stock': stock,
                  'price': price,
                  'category': selectedCategory,
                  'timestamp': FieldValue.serverTimestamp(),
                };
                if (docId == null) {
                  await _firestore.collection('products').add(data);
                } else {
                  await _firestore
                      .collection('products')
                      .doc(docId)
                      .update(data);
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Error: $e',
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
              text: docId == null ? 'Add' : 'Update',
              fontSize: 14,
              fontFamily: 'Medium',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(String docId) async {
    try {
      await _firestore.collection('products').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Product deleted successfully',
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
            text: 'Error deleting product: $e',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  Future<void> _deleteIngredient(String docId) async {
    try {
      await _firestore.collection('ingredients').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Ingredient deleted successfully',
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
            text: 'Error deleting ingredient: $e',
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
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
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
                controller: _searchController,
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
                        color: AppTheme.primaryColor,
                        textColor: Colors.white,
                        label: 'Add Ingredient',
                        onPressed: () {
                          _showUpdateIngredientDialog(context, null, '', 0.0);
                        },
                        fontSize: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _searchQuery.isEmpty
                          ? _firestore
                              .collection('ingredients')
                              .orderBy('timestamp', descending: true)
                              .snapshots()
                          : _firestore
                              .collection('ingredients')
                              .where('searchName',
                                  isGreaterThanOrEqualTo: _searchQuery)
                              .where('searchName',
                                  isLessThanOrEqualTo: '$_searchQuery\uf8ff')
                              .orderBy('searchName')
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
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final ingredients = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: ingredients.length,
                          itemBuilder: (context, index) {
                            final ingredient = ingredients[index];
                            final data =
                                ingredient.data() as Map<String, dynamic>;
                            final isLowStock = (data['quantity'] as num) < 2;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
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
                                                text: data['name'] ?? 'Unnamed',
                                                fontSize: 18,
                                                fontFamily: 'Medium',
                                                color: Colors.grey[800],
                                              ),
                                              if (isLowStock) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
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
                                                'Quantity: ${data['quantity']} kg',
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
                                                context,
                                                ingredient.id,
                                                data['name'] ?? '',
                                                (data['quantity'] as num)
                                                    .toDouble(),
                                              );
                                            },
                                            icon: Icon(
                                              Icons.edit,
                                              color: AppTheme.primaryColor,
                                              size: 26,
                                            ),
                                            tooltip: 'Update Ingredient',
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              _deleteIngredient(ingredient.id);
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                        color: AppTheme.primaryColor,
                        textColor: Colors.white,
                        label: 'Add Product',
                        onPressed: () {
                          _showUpdateProductDialog(
                              context, null, '', 0, 0.0, '');
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
                    child: StreamBuilder<QuerySnapshot>(
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
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final products = snapshot.data!.docs;

                        // Filter products by category and search query
                        final filteredProducts = products.where((product) {
                          final data = product.data() as Map<String, dynamic>;
                          final productName =
                              (data['name'] as String?)?.toLowerCase() ?? '';
                          final productCategory =
                              data['category'] as String? ?? '';

                          // Filter by category if not 'All'
                          if (_selectedCategory != 'All' &&
                              productCategory != _selectedCategory) {
                            return false;
                          }

                          // If searching, also filter by name
                          if (_searchQuery.isNotEmpty) {
                            return productName
                                .contains(_searchQuery.toLowerCase());
                          }

                          return true;
                        }).toList();

                        // Show "No results found" message if no products match
                        if (filteredProducts.isEmpty &&
                            _searchQuery.isNotEmpty) {
                          return Center(
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
                                  text: 'No products found for "$_searchQuery"',
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
                          );
                        }

                        return ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final data = product.data() as Map<String, dynamic>;
                            final isLowStock = (data['stock'] as num) < 20;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
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
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor:
                                                AppTheme.primaryColor.withOpacity(0.1),
                                            child: Icon(
                                              _getCategoryIcon(
                                                  data['category'] ?? 'Foods'),
                                              color: AppTheme.primaryColor,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  TextWidget(
                                                    text: data['name'] ??
                                                        'Unnamed',
                                                    fontSize: 18,
                                                    fontFamily: 'Medium',
                                                    color: Colors.grey[800],
                                                  ),
                                                  if (isLowStock) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red[50],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
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
                                                    'Category: ${data['category'] ?? 'N/A'}',
                                                fontSize: 14,
                                                fontFamily: 'Regular',
                                                color: Colors.grey[600],
                                              ),
                                              TextWidget(
                                                text:
                                                    'Stock: ${data['stock'] ?? 0} units',
                                                fontSize: 14,
                                                fontFamily: 'Regular',
                                                color: Colors.grey[600],
                                              ),
                                              TextWidget(
                                                text:
                                                    'Price: P${(data['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                                fontSize: 14,
                                                fontFamily: 'Regular',
                                                color: Colors.grey[600],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              _showUpdateProductDialog(
                                                context,
                                                product.id,
                                                data['name'] ?? '',
                                                (data['stock'] as num?)
                                                        ?.toInt() ??
                                                    0,
                                                (data['price'] as num?)
                                                        ?.toDouble() ??
                                                    0.0,
                                                data['category'] ?? '',
                                              );
                                            },
                                            icon: Icon(
                                              Icons.edit,
                                              color: AppTheme.primaryColor,
                                              size: 26,
                                            ),
                                            tooltip: 'Update Product',
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              _deleteProduct(product.id);
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
        color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
