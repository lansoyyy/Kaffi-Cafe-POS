import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/utils/branch_service.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentBranch;

  @override
  void initState() {
    super.initState();
    _getCurrentBranch();
  }

  Future<void> _getCurrentBranch() async {
    final currentBranch = await BranchService.getSelectedBranch();
    if (mounted) {
      setState(() {
        _currentBranch = currentBranch;
      });
    }
  }

  String _getOrderStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'New order received';
      case 'Accepted':
        return 'Order is being prepared';
      case 'Ready to Pickup':
        return 'Order is ready for pickup';
      case 'Completed':
        return 'Order completed';
      default:
        return 'Order status updated';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.blue;
      case 'Ready to Pickup':
        return Colors.green;
      case 'Completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.pending_actions;
      case 'Accepted':
        return Icons.restaurant;
      case 'Ready to Pickup':
        return Icons.check_circle;
      case 'Completed':
        return Icons.done_all;
      default:
        return Icons.notifications;
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
          children: [
            const Icon(Icons.notifications, size: 24),
            const SizedBox(width: 12),
            TextWidget(
              text: 'Notifications',
              fontSize: 20,
              fontFamily: 'Bold',
              color: Colors.white,
            ),
            const SizedBox(width: 20),
            if (_currentBranch != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    TextWidget(
                      text: _currentBranch!,
                      fontSize: 14,
                      fontFamily: 'Medium',
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      drawer: const DrawerWidget(),
      body: _currentBranch == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('orders')
                  .where('branch', isEqualTo: _currentBranch)
                  .orderBy('timestamp', descending: true)
                  .limit(50) // Limit to last 50 orders
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

                final orders = snapshot.data!.docs;

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        TextWidget(
                          text: 'No notifications yet',
                          fontSize: 18,
                          fontFamily: 'Medium',
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        TextWidget(
                          text: 'Order notifications will appear here',
                          fontSize: 14,
                          fontFamily: 'Regular',
                          color: Colors.grey[500],
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final data = order.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'Pending';
                    final timestamp = data['timestamp'] as Timestamp?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(status).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getStatusIcon(status),
                                    color: _getStatusColor(status),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextWidget(
                                        text: _getOrderStatusText(status),
                                        fontSize: 16,
                                        fontFamily: 'Bold',
                                        color: _getStatusColor(status),
                                      ),
                                      const SizedBox(height: 4),
                                      TextWidget(
                                        text:
                                            'Order #${data['orderId'] ?? 'N/A'}',
                                        fontSize: 14,
                                        fontFamily: 'Medium',
                                        color: Colors.grey[700],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextWidget(
                                    text: status,
                                    fontSize: 12,
                                    fontFamily: 'Medium',
                                    color: _getStatusColor(status),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextWidget(
                              text: 'Customer: ${data['buyer'] ?? 'Unknown'}',
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 4),
                            TextWidget(
                              text:
                                  'Total: P${(data['total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: Colors.grey[700],
                            ),
                            if (timestamp != null) ...[
                              const SizedBox(height: 8),
                              TextWidget(
                                text: DateFormat('MMM dd, yyyy HH:mm')
                                    .format(timestamp.toDate()),
                                fontSize: 12,
                                fontFamily: 'Regular',
                                color: Colors.grey[500],
                              ),
                            ],
                            if (data['paymentMethod'] != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.payment,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  TextWidget(
                                    text: 'Payment: ${data['paymentMethod']}',
                                    fontSize: 12,
                                    fontFamily: 'Regular',
                                    color: Colors.grey[500],
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
