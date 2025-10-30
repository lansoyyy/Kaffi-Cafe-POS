import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/utils/branch_service.dart';
import 'package:kaffi_cafe_pos/utils/notification_service.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  String? _currentBranch;
  late Stream<QuerySnapshot> _ordersStream;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();

    // Initialize NotificationService
    _notificationService.init().then((_) {
      _getCurrentBranch();
    });
  }

  void _setupOrdersStream() {
    if (_currentBranch == null) return;

    _ordersStream = _firestore
        .collection('orders')
        .where('branch', isEqualTo: _currentBranch)
        .orderBy('timestamp', descending: true)
        .limit(50) // Limit to last 50 orders
        .snapshots();

    // Force a rebuild to update the stream
    setState(() {});
  }

  Future<void> _getCurrentBranch() async {
    final currentBranch = BranchService.getSelectedBranch();
    if (mounted) {
      setState(() {
        _currentBranch = currentBranch;
      });
      // Set up the orders stream after getting the branch
      _setupOrdersStream();
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
        automaticallyImplyLeading: true,
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
      body: _currentBranch == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _ordersStream,
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

                // Calculate unread count
                final orderIds = orders.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['orderId']?.toString() ?? '';
                }).toList();
                final unreadCount =
                    _notificationService.getUnreadCount(orderIds);

                // Update unread count state to trigger real-time updates
                if (_unreadCount != unreadCount) {
                  _unreadCount = unreadCount;
                }

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

                return Column(
                  children: [
                    // Add header with unread count
                    if (unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            TextWidget(
                              text:
                                  'You have $unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                              fontSize: 14,
                              fontFamily: 'Medium',
                              color: Colors.blue[700],
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                // Mark all as read
                                for (final orderId in orderIds) {
                                  _notificationService.markAsRead(orderId);
                                }
                                // Force a rebuild to update the UI
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                              child: TextWidget(
                                text: 'Mark all as read',
                                fontSize: 12,
                                fontFamily: 'Medium',
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final data = order.data() as Map<String, dynamic>;
                          final status = data['status'] ?? 'Pending';
                          final timestamp = data['timestamp'] as Timestamp?;
                          final orderId = data['orderId']?.toString() ?? '';
                          final isRead = _notificationService.isRead(orderId);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            elevation: isRead ? 1 : 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isRead
                                    ? Colors.grey[300]!
                                    : _getStatusColor(status).withOpacity(0.5),
                                width: isRead ? 1 : 2,
                              ),
                            ),
                            child: InkWell(
                              onTap: () async {
                                // Mark notification as read when clicked
                                _notificationService.markAsRead(orderId);
                                // Force a rebuild to update the UI
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: isRead
                                      ? null
                                      : LinearGradient(
                                          colors: [
                                            _getStatusColor(status)
                                                .withOpacity(0.05),
                                            _getStatusColor(status)
                                                .withOpacity(0.02),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  color:
                                      isRead ? Colors.grey[50] : Colors.white,
                                  boxShadow: isRead
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: _getStatusColor(status)
                                                .withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Stack(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(status)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _getStatusIcon(status),
                                                color: _getStatusColor(status),
                                                size: 24,
                                              ),
                                            ),
                                            if (!isRead)
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  TextWidget(
                                                    text: _getOrderStatusText(
                                                        status),
                                                    fontSize: 16,
                                                    fontFamily: isRead
                                                        ? 'Medium'
                                                        : 'Bold',
                                                    color: isRead
                                                        ? Colors.grey[700]
                                                        : _getStatusColor(
                                                            status),
                                                  ),
                                                  if (!isRead) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: TextWidget(
                                                        text: 'NEW',
                                                        fontSize: 8,
                                                        fontFamily: 'Bold',
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              TextWidget(
                                                text:
                                                    'Order #${data['orderId'] ?? 'N/A'}',
                                                fontSize: 14,
                                                fontFamily: 'Medium',
                                                color: isRead
                                                    ? Colors.grey[600]
                                                    : Colors.grey[700],
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
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                                      text:
                                          'Customer: ${data['buyer'] ?? 'Unknown'}',
                                      fontSize: 14,
                                      fontFamily: 'Regular',
                                      color: isRead
                                          ? Colors.grey[600]
                                          : Colors.grey[700],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        TextWidget(
                                          text: 'Total: ',
                                          fontSize: 14,
                                          fontFamily: 'Regular',
                                          color: isRead
                                              ? Colors.grey[600]
                                              : Colors.grey[700],
                                        ),
                                        TextWidget(
                                          text:
                                              'P${(data['total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                          fontSize: 14,
                                          fontFamily:
                                              isRead ? 'Medium' : 'Bold',
                                          color: isRead
                                              ? Colors.grey[600]
                                              : Colors.grey[800],
                                        ),
                                      ],
                                    ),
                                    if (timestamp != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: isRead
                                                ? Colors.grey[400]
                                                : Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          TextWidget(
                                            text:
                                                DateFormat('MMM dd, yyyy HH:mm')
                                                    .format(timestamp.toDate()),
                                            fontSize: 12,
                                            fontFamily: 'Regular',
                                            color: isRead
                                                ? Colors.grey[400]
                                                : Colors.grey[500],
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (data['paymentMethod'] != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.payment,
                                            size: 14,
                                            color: isRead
                                                ? Colors.grey[400]
                                                : Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          TextWidget(
                                            text:
                                                'Payment: ${data['paymentMethod']}',
                                            fontSize: 12,
                                            fontFamily: 'Regular',
                                            color: isRead
                                                ? Colors.grey[400]
                                                : Colors.grey[500],
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (!isRead)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.touch_app,
                                              size: 12,
                                              color: _getStatusColor(status),
                                            ),
                                            const SizedBox(width: 4),
                                            TextWidget(
                                              text: 'Tap to mark as read',
                                              fontSize: 10,
                                              fontFamily: 'Medium',
                                              color: _getStatusColor(status),
                                            ),
                                          ],
                                        ),
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
                );
              },
            ),
    );
  }
}
