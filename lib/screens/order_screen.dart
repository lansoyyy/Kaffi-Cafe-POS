import 'package:flutter/material.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: 3, // Sample order count
          itemBuilder: (context, index) {
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
                            text: 'Order #${index + 1001}',
                            fontSize: 18,
                            fontFamily: 'Bold',
                            color: Colors.grey[800],
                          ),
                          TextWidget(
                            text: 'Pending',
                            fontSize: 14,
                            fontFamily: 'Medium',
                            color: Colors.orange[600],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextWidget(
                        text: 'Buyer: John Doe',
                        fontSize: 16,
                        fontFamily: 'Medium',
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.grey, thickness: 0.5),
                      const SizedBox(height: 12),
                      // Order Items
                      Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextWidget(
                                  text: 'x2',
                                  fontSize: 14,
                                  fontFamily: 'Bold',
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextWidget(
                                  text: 'Caramel Macchiato',
                                  fontSize: 16,
                                  fontFamily: 'Regular',
                                  color: Colors.grey[800],
                                ),
                              ),
                              TextWidget(
                                text: 'P150.00',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextWidget(
                                  text: 'x1',
                                  fontSize: 14,
                                  fontFamily: 'Bold',
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextWidget(
                                  text: 'Croissant',
                                  fontSize: 16,
                                  fontFamily: 'Regular',
                                  color: Colors.grey[800],
                                ),
                              ),
                              TextWidget(
                                text: 'P80.00',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ],
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
                            text: 'P380.00',
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
                          ElevatedButton(
                            onPressed: () {
                              // Decline order logic
                            },
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
                            onPressed: () {
                              // Accept order logic
                            },
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
          },
        ),
      ),
    );
  }
}
