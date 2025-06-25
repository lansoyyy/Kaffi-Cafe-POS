import 'package:flutter/material.dart';
import 'package:kaffi_cafe_pos/screens/inventory_screen.dart';
import 'package:kaffi_cafe_pos/screens/order_screen.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/widgets/divider_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';

import '../screens/home_screen.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: bayanihanBlue,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                  Icons.point_of_sale,
                  color: Colors.white,
                  size: 26,
                ),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                title: TextWidget(
                  text: 'POS Register',
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
                  Icons.phone,
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
                  text: 'Inventory',
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
                  Icons.grading_sharp,
                  color: Colors.white,
                  size: 26,
                ),
                onTap: () {
                  // Navigator.pushReplacement(
                  //   context,
                  //   MaterialPageRoute(
                  //       builder: (context) => const InventoryScreen()),
                  // );
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
              // ListTile(
              //   leading: const Icon(
              //     Icons.inventory_2_outlined,
              //     color: Colors.white,
              //     size: 26,
              //   ),
              //   onTap: () {},
              //   title: TextWidget(
              //     text: 'Inventory',
              //     fontSize: 16,
              //     fontFamily: 'Medium',
              //     color: Colors.white,
              //   ),
              //   hoverColor: Colors.white10,
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              // ),
              // ListTile(
              //   leading: const Icon(
              //     Icons.bar_chart_rounded,
              //     color: Colors.white,
              //     size: 26,
              //   ),
              //   onTap: () {},
              //   title: TextWidget(
              //     text: 'Reports',
              //     fontSize: 16,
              //     fontFamily: 'Medium',
              //     color: Colors.white,
              //   ),
              //   hoverColor: Colors.white10,
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              // ),
              // ListTile(
              //   leading: const Icon(
              //     Icons.settings_outlined,
              //     color: Colors.white,
              //     size: 26,
              //   ),
              //   onTap: () {},
              //   title: TextWidget(
              //     text: 'Settings',
              //     fontSize: 16,
              //     fontFamily: 'Medium',
              //     color: Colors.white,
              //   ),
              //   hoverColor: Colors.white10,
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              // ),
              // const Spacer(),
              // const Divider(color: Colors.white24, thickness: 1),
              // const SizedBox(height: 10),
              // ListTile(
              //   leading: const Icon(
              //     Icons.logout_rounded,
              //     color: Colors.redAccent,
              //     size: 26,
              //   ),
              //   onTap: () {
              //     // Implement logout logic
              //   },
              //   title: TextWidget(
              //     text: 'Logout',
              //     fontSize: 16,
              //     fontFamily: 'Medium',
              //     color: Colors.redAccent,
              //   ),
              //   hoverColor: Colors.white10,
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
