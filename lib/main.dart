import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaffi_cafe_pos/firebase_options.dart';
import 'package:kaffi_cafe_pos/screens/staff_screen.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    name: 'kaffi-cafe',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize app theme from Firebase
  await AppTheme.initializeTheme();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaffi Cafe POS',
      theme: AppTheme.theme,
      home: const StaffScreen(),
    );
  }
}
