import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'colors.dart';

class AppTheme {
  static Color _primaryColor = primaryBlue;
  static Color _secondaryColor = bayanihanBlue;

  // Getters for the current theme colors
  static Color get primaryColor => _primaryColor;
  static Color get secondaryColor => _secondaryColor;

  // Initialize theme colors from Firebase
  static Future<void> initializeTheme() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('business')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final primaryColorValue = data['primaryColor'] as int?;

        if (primaryColorValue != null) {
          _primaryColor = Color(primaryColorValue);
          _secondaryColor = Color(primaryColorValue);
        }
      }
    } catch (e) {
      // If there's an error, keep the default colors
      print('Error loading theme colors: $e');
    }
  }

  // Update theme colors (called when settings are saved)
  static void updatePrimaryColor(Color newColor) {
    _primaryColor = newColor;
    _secondaryColor = newColor;
  }

  // Get the current theme data
  static ThemeData get theme => ThemeData(
        primaryColor: _primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          primary: _primaryColor,
          secondary: _secondaryColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
      );
}
