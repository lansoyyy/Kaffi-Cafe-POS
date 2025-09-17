import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kaffi_cafe_pos/firebase_options.dart';
import 'package:kaffi_cafe_pos/screens/branch_selection_screen.dart';
import 'package:kaffi_cafe_pos/screens/staff_screen.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/utils/branch_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage
  await GetStorage.init();

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
      initialRoute: '/',
      routes: {
        '/': (context) => const InitialScreen(),
        '/branch': (context) => const BranchSelectionScreen(),
        '/staff': (context) => const StaffScreen(),
      },
    );
  }
}

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if a branch is already selected
    if (BranchService.isBranchSelected()) {
      // If branch is selected, go to staff login
      return const StaffScreen();
    } else {
      // If no branch is selected, go to branch selection
      return const BranchSelectionScreen();
    }
  }
}
