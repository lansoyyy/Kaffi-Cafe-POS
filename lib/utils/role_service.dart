import 'package:shared_preferences/shared_preferences.dart';

class RoleService {
  // Hardcoded Super Admin credentials
  static const String superAdminUsername = 'superadmin';
  static const String superAdminPin = '9999';
  static const String superAdminRole = 'super_admin';
  static const String staffRole = 'staff';

  // Check if current user is Super Admin
  static Future<bool> isSuperAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? staffRole;
    return role == superAdminRole;
  }

  // Get current user role
  static Future<String> getCurrentRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role') ?? staffRole;
  }

  // Set user role
  static Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  // Check if login is Super Admin
  static bool isSuperAdminLogin(String username, String pin) {
    return username.toLowerCase() == superAdminUsername.toLowerCase() && 
           pin == superAdminPin;
  }

  // Clear user role on logout
  static Future<void> clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
  }
}
