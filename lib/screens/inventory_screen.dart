import 'package:flutter/material.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  // Dialog for updating ingredient details
  void _showUpdateIngredientDialog(
      BuildContext context, String ingredientName, double quantity) {
    final nameController = TextEditingController(text: ingredientName);
    final quantityController = TextEditingController(text: quantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: bayanihanBlue,
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
  void _showUpdateProductDialog(
      BuildContext context, String productName, int stock, double price) {
    final nameController = TextEditingController(text: productName);
    final stockController = TextEditingController(text: stock.toString());
    final priceController = TextEditingController(text: price.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: TextWidget(
          text: 'Update Product',
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
                labelText: 'Product Name',
                labelStyle: TextStyle(color: Colors.grey[600]),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Stock (units)',
                labelStyle: TextStyle(color: Colors.grey[600]),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price (P)',
                labelStyle: TextStyle(color: Colors.grey[600]),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: bayanihanBlue,
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
        backgroundColor: bayanihanBlue,
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
                      ElevatedButton.icon(
                        onPressed: () {
                          _showUpdateIngredientDialog(
                              context, '', 0.0); // Empty for new ingredient
                        },
                        icon: const Icon(
                          Icons.add,
                          size: 22,
                          color: Colors.white,
                        ),
                        label: TextWidget(
                          text: 'Add Ingredient',
                          fontSize: 16,
                          fontFamily: 'Medium',
                          color: Colors.white,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bayanihanBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          elevation: 2,
                        ),
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
                                          color: Colors.blue[600],
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
                      ElevatedButton.icon(
                        onPressed: () {
                          _showUpdateProductDialog(
                              context, '', 0, 0.0); // Empty for new product
                        },
                        icon: const Icon(
                          Icons.add,
                          size: 22,
                          color: Colors.white,
                        ),
                        label: TextWidget(
                          text: 'Add Product',
                          fontSize: 16,
                          fontFamily: 'Medium',
                          color: Colors.white,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bayanihanBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 3, // Sample product count
                      itemBuilder: (context, index) {
                        final isLowStock =
                            index == 1; // Example condition for low stock
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
                                            text: 'Caramel Macchiato',
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
                                        text: 'Stock: 50 units',
                                        fontSize: 14,
                                        fontFamily: 'Regular',
                                        color: Colors.grey[600],
                                      ),
                                      TextWidget(
                                        text: 'Price: P150.00',
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
                                          _showUpdateProductDialog(context,
                                              'Caramel Macchiato', 50, 150.0);
                                        },
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.blue[600],
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
}
