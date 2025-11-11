import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/utils/branch_service.dart';
import 'package:kaffi_cafe_pos/utils/role_service.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';
import 'package:kaffi_cafe_pos/widgets/textfield_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kaffi_cafe_pos/screens/staff_screen.dart';
import 'package:kaffi_cafe_pos/screens/home_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _selectedCategory = 'All';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoggedIn = false;
  File? _selectedImage;
  String? _currentBranch;

  final List<String> _categories = [
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
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_staff_logged_in') ?? false;
    final currentBranch = BranchService.getSelectedBranch();
    final isSuperAdmin = await RoleService.isSuperAdmin();

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

    if (false) {
      // Redirect to home screen if not Super Admin
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = true;
        _currentBranch = currentBranch;
      });
    }
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
                labelText: 'Quantity (kg)',
                labelStyle: TextStyle(color: Colors.grey[600]),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: AppTheme.primaryColor, width: 2),
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

  void _showUpdateProductDialog(
      BuildContext context,
      String? docId,
      String productName,
      int stock,
      double price,
      String category,
      String imageUrl,
      String description,
      String ingredients) {
    final nameController = TextEditingController(text: productName);
    final priceController = TextEditingController(text: price.toString());
    final descriptionController = TextEditingController(text: description);
    final ingredientsController = TextEditingController(text: ingredients);
    String selectedCategory = category.isEmpty ? 'Coffee' : category;
    String currentImageUrl = imageUrl;
    File? newImage;

    // Function to upload image to Firebase Storage
    Future<String?> _uploadImage(String productId) async {
      if (newImage == null) return currentImageUrl;

      try {
        final ref =
            _storage.ref().child('product_images').child('$productId.jpg');
        await ref.putFile(newImage!);
        final url = await ref.getDownloadURL();
        return url;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: 'Error uploading image: $e',
              fontSize: 14,
              fontFamily: 'Regular',
              color: Colors.white,
            ),
            backgroundColor: Colors.red[600],
          ),
        );
        return null;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          title: TextWidget(
            text: docId == null ? 'Add Product' : 'Update Product',
            fontSize: 18,
            fontFamily: 'Bold',
            color: Colors.grey[800],
          ),
          content: StatefulBuilder(builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image picker section
                  GestureDetector(
                    onTap: () async {
                      final XFile? pickedFile = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 50,
                      );

                      if (pickedFile != null) {
                        setState(() {
                          newImage = File(pickedFile.path);
                        });
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: newImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                newImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : currentImageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    currentImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: Colors.grey,
                                      );
                                    },
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 10),
                                    Text('Tap to add image'),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
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
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                    items: [
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
                    ].map((category) {
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
                    controller: descriptionController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
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
                    controller: ingredientsController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Ingredients',
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
                      labelText: 'Price (P)',
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
                ],
              ),
            );
          }),
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
                    priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: TextWidget(
                        text: 'Please fill in all required fields',
                        fontSize: 14,
                        fontFamily: 'Regular',
                        color: Colors.white,
                      ),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                  return;
                }
                final price = double.tryParse(priceController.text);
                if (price == null || price < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: TextWidget(
                        text: 'Invalid price',
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
                    'price': price,
                    'category': selectedCategory,
                    'description': descriptionController.text,
                    'ingredients': ingredientsController.text,
                    'image': '', // Initialize with empty string
                    'branch': _currentBranch, // Add branch information
                    'timestamp': FieldValue.serverTimestamp(),
                  };

                  String? productId;
                  if (docId == null) {
                    // Adding new product
                    final docRef =
                        await _firestore.collection('products').add(data);
                    productId = docRef.id;
                  } else {
                    // Updating existing product
                    await _firestore
                        .collection('products')
                        .doc(docId)
                        .update(data);
                    productId = docId;
                  }

                  // Upload image if selected
                  if (newImage != null && productId != null) {
                    final imageUrl = await _uploadImage(productId);
                    if (imageUrl != null) {
                      await _firestore
                          .collection('products')
                          .doc(productId)
                          .update({'image': imageUrl});
                    }
                  }

                  Navigator.pop(context);
                } catch (e) {}
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
        );
      }),
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
      case 'Non-Coffee Drinks':
        return Icons.local_bar;
      case 'Pastries':
        return Icons.cake;
      case 'Sandwiches':
        return Icons.lunch_dining;
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
      case 'Add-ons':
        return Icons.add_shopping_cart;
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
              fontSize: 24,
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
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white70, size: 28),
                    hintText: 'Search inventory...',
                    hintStyle: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Regular',
                      fontSize: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                        text: 'Menu Products',
                        fontSize: 24,
                        fontFamily: 'Bold',
                        color: Colors.grey[800],
                      ),
                      ButtonWidget(
                        radius: 16,
                        color: AppTheme.primaryColor,
                        textColor: Colors.white,
                        label: 'Add Product',
                        onPressed: () {
                          _showUpdateProductDialog(
                              context, null, '', 0, 0.0, '', '', '', '');
                        },
                        fontSize: 18,
                        width: 180,
                        height: 56,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 70,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _categories.map((category) {
                        return _buildCategoryButton(category);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
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
                              fontSize: 18,
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
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 20),
                                TextWidget(
                                  text: 'No products found for "$_searchQuery"',
                                  fontSize: 22,
                                  fontFamily: 'Medium',
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 12),
                                TextWidget(
                                  text: 'Try a different search term',
                                  fontSize: 16,
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
                            final isLowStock = false; // Stock is no longer used
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              child: Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(20.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isLowStock
                                          ? Colors.red[300]!
                                          : Colors.grey[200]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: data['image'] != null &&
                                                    data['image'] != ''
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    child: Image.network(
                                                      data['image'],
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Icon(
                                                          _getCategoryIcon(data[
                                                                  'category'] ??
                                                              'Foods'),
                                                          color: AppTheme
                                                              .primaryColor,
                                                          size: 32,
                                                        );
                                                      },
                                                    ),
                                                  )
                                                : Icon(
                                                    _getCategoryIcon(
                                                        data['category'] ??
                                                            'Foods'),
                                                    color:
                                                        AppTheme.primaryColor,
                                                    size: 32,
                                                  ),
                                          ),
                                          const SizedBox(width: 20),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  TextWidget(
                                                    text: data['name'] ??
                                                        'Unnamed',
                                                    fontSize: 20,
                                                    fontFamily: 'Bold',
                                                    color: Colors.grey[800],
                                                  ),
                                                  if (isLowStock) ...[
                                                    const SizedBox(width: 12),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red[50],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: TextWidget(
                                                        text: 'LOW STOCK',
                                                        fontSize: 14,
                                                        fontFamily: 'Bold',
                                                        color: Colors.red[600],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              TextWidget(
                                                text:
                                                    'Category: ${data['category'] ?? 'N/A'}',
                                                fontSize: 16,
                                                fontFamily: 'Medium',
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(height: 4),
                                              TextWidget(
                                                text:
                                                    'Description: ${data['description'] ?? 'No description'}',
                                                fontSize: 16,
                                                fontFamily: 'Medium',
                                                color: Colors.grey[600],
                                                maxLines: 2,
                                              ),
                                              const SizedBox(height: 4),
                                              TextWidget(
                                                text:
                                                    'Ingredients: ${data['ingredients'] ?? 'No ingredients listed'}',
                                                fontSize: 16,
                                                fontFamily: 'Medium',
                                                color: Colors.grey[600],
                                                maxLines: 2,
                                              ),
                                              const SizedBox(height: 4),
                                              TextWidget(
                                                text:
                                                    'Price: ₱${(data['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                                fontSize: 18,
                                                fontFamily: 'Bold',
                                                color: AppTheme.primaryColor,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: IconButton(
                                              onPressed: () {
                                                _showUpdateProductDialog(
                                                  context,
                                                  product.id,
                                                  data['name'] ?? '',
                                                  0, // Stock is no longer used
                                                  (data['price'] as num?)
                                                          ?.toDouble() ??
                                                      0.0,
                                                  data['category'] ?? '',
                                                  data['image'] ?? '',
                                                  data['description'] ?? '',
                                                  data['ingredients'] ?? '',
                                                );
                                              },
                                              icon: Icon(
                                                Icons.edit,
                                                color: AppTheme.primaryColor,
                                                size: 32,
                                              ),
                                              padding: const EdgeInsets.all(16),
                                              splashRadius: 30,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: IconButton(
                                              onPressed: () {
                                                _deleteProduct(product.id);
                                              },
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.red[400],
                                                size: 32,
                                              ),
                                              padding: const EdgeInsets.all(16),
                                              splashRadius: 30,
                                            ),
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
      padding: const EdgeInsets.only(right: 12.0),
      child: ButtonWidget(
        width: 180,
        height: 60,
        radius: 16,
        color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
        textColor: isSelected ? Colors.white : Colors.grey[800],
        label: category,
        onPressed: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        fontSize: 16,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
