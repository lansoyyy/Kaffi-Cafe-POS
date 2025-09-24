import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaffi_cafe_pos/main.dart';
import 'package:kaffi_cafe_pos/screens/inventory_screen.dart';
import 'package:kaffi_cafe_pos/screens/order_screen.dart';
import 'package:kaffi_cafe_pos/screens/receipt_screen.dart';
import 'package:kaffi_cafe_pos/screens/reports_screen.dart';
import 'package:kaffi_cafe_pos/screens/reservation_screen.dart';
import 'package:kaffi_cafe_pos/screens/settings_screen.dart';
import 'package:kaffi_cafe_pos/screens/transaction_screen.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/utils/branch_service.dart';
import 'package:kaffi_cafe_pos/utils/role_service.dart';
import 'package:kaffi_cafe_pos/widgets/divider_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home_screen.dart';
import '../screens/staff_screen.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final isSuperAdmin = await RoleService.isSuperAdmin();
    if (mounted) {
      setState(() {
        _isSuperAdmin = isSuperAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppTheme.primaryColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                const Divider(color: Colors.white24, thickness: 1),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(
                    Icons.store_mall_directory_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                    );
                  },
                  title: TextWidget(
                    text: 'Orders',
                    fontSize: 16,
                    fontFamily: 'Medium',
                    color: Colors.white,
                  ),
                  hoverColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                DividerWidget(),
                ListTile(
                  leading: const Icon(
                    Icons.mobile_friendly_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OrderScreen()),
                    );
                  },
                  title: TextWidget(
                    text: 'Online Orders',
                    fontSize: 16,
                    fontFamily: 'Medium',
                    color: Colors.white,
                  ),
                  hoverColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                DividerWidget(),
                ListTile(
                  leading: const Icon(
                    Icons.table_bar_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ReservationScreen()),
                    );
                  },
                  title: TextWidget(
                    text: 'Reservations',
                    fontSize: 16,
                    fontFamily: 'Medium',
                    color: Colors.white,
                  ),
                  hoverColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                DividerWidget(),
                if (_isSuperAdmin) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 26,
                    ),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const InventoryScreen()),
                      );
                    },
                    title: TextWidget(
                      text: 'Products',
                      fontSize: 16,
                      fontFamily: 'Medium',
                      color: Colors.white,
                    ),
                    hoverColor: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  DividerWidget(),
                ],
                ListTile(
                  leading: const Icon(
                    Icons.grading_sharp,
                    color: Colors.white,
                    size: 26,
                  ),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SalesReportScreen()),
                    );
                  },
                  title: TextWidget(
                    text: 'Reports',
                    fontSize: 16,
                    fontFamily: 'Medium',
                    color: Colors.white,
                  ),
                  hoverColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                DividerWidget(),
                ListTile(
                  leading: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 26,
                  ),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TransactionScreen()),
                    );
                  },
                  title: TextWidget(
                    text: 'Transactions',
                    fontSize: 16,
                    fontFamily: 'Medium',
                    color: Colors.white,
                  ),
                  hoverColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                DividerWidget(),
                if (_isSuperAdmin) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 26,
                    ),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const StaffScreen()),
                      );
                    },
                    title: TextWidget(
                      text: 'Staff Management',
                      fontSize: 16,
                      fontFamily: 'Medium',
                      color: Colors.white,
                    ),
                    hoverColor: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  DividerWidget(),
                ],
                if (_isSuperAdmin) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 26,
                    ),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      );
                    },
                    title: TextWidget(
                      text: 'Settings',
                      fontSize: 16,
                      fontFamily: 'Medium',
                      color: Colors.white,
                    ),
                    hoverColor: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
                DividerWidget(),
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 26,
                  ),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('is_staff_logged_in', false);
                    await prefs.remove('current_staff_name');
                    await prefs.remove('current_staff_id');
                    await RoleService.clearUserRole();

                    // Update branch isOnline status
                    final currentBranch = BranchService.getSelectedBranch();

                    print(currentBranch);
                    if (currentBranch != null) {
                      final FirebaseFirestore firestore =
                          FirebaseFirestore.instance;
                      await firestore
                          .collection('branches')
                          .doc(currentBranch == 'Kaffi Cafe - Eloisa St'
                              ? 'branch1'
                              : 'branch2')
                          .update({
                        'isOnline': false,
                      });
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const InitialScreen()),
                    );
                  },
                  title: TextWidget(
                    text: 'Logout',
                    fontSize: 16,
                    fontFamily: 'Medium',
                    color: Colors.white,
                  ),
                  hoverColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
