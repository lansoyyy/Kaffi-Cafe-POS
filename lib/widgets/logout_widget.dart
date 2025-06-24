// import 'package:auth0_flutter/auth0_flutter.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:customer_loyalty/screens/auth/landing_screen.dart';

// logout(BuildContext context, Widget navigationRoute) {
//   final box = GetStorage();
//   late Auth0 auth0 = Auth0(
//       'dev-1x4l6wkco1ygo6sx.us.auth0.com', 'C45lX9RRB8yqdUHCvBjXOeDtnhYBpVh0');
//   return showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//             title: const Text(
//               'Logout Confirmation',
//               style: TextStyle(fontFamily: 'Bold', fontWeight: FontWeight.bold),
//             ),
//             content: const Text(
//               'Are you sure you want to Logout?',
//               style: TextStyle(fontFamily: 'Regular'),
//             ),
//             actions: <Widget>[
//               MaterialButton(
//                 onPressed: () => Navigator.of(context).pop(true),
//                 child: const Text(
//                   'Close',
//                   style: TextStyle(
//                       fontFamily: 'Regular', fontWeight: FontWeight.bold),
//                 ),
//               ),
//               MaterialButton(
//                 onPressed: () async {
//                   box.erase();
//                   Get.off(LandingScreen(),
//                       transition: Transition.circularReveal);
//                 },
//                 child: const Text(
//                   'Continue',
//                   style: TextStyle(
//                       fontFamily: 'Regular', fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ],
//           ));
// }
