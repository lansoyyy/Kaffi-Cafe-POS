import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';
import 'package:kaffi_cafe_pos/widgets/textfield_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kaffi_cafe_pos/screens/home_screen.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _loginPinController = TextEditingController();

  String _selectedStaff = '';
  bool _isCreatingStaff = false;
  bool _isLoggedIn = false;
  String _currentStaffName = '';
  String _currentStaffId = '';

  @override
  void initState() {
    super.initState();
    _checkLoggedInStatus();
  }

  Future<void> _checkLoggedInStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_staff_logged_in') ?? false;
    final staffName = prefs.getString('current_staff_name') ?? '';
    final staffId = prefs.getString('current_staff_id') ?? '';

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _currentStaffName = staffName;
        _currentStaffId = staffId;
      });
    }
  }

  Future<void> _createStaff() async {
    if (_nameController.text.isEmpty ||
        _positionController.text.isEmpty ||
        _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Please fill in all fields',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    // PIN should be 4 digits
    if (_pinController.text.length != 4 ||
        int.tryParse(_pinController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'PIN must be a 4-digit number',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    try {
      await _firestore.collection('staff').add({
        'name': _nameController.text,
        'position': _positionController.text,
        'pin': _pinController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear form
      _nameController.clear();
      _positionController.clear();
      _pinController.clear();

      if (mounted) {
        setState(() {
          _isCreatingStaff = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: 'Staff member created successfully',
              fontSize: 14,
              fontFamily: 'Regular',
              color: Colors.white,
            ),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: 'Error creating staff: $e',
              fontSize: 14,
              fontFamily: 'Regular',
              color: Colors.white,
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<void> _loginStaff() async {
    if (_selectedStaff.isEmpty || _loginPinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Please select a staff member and enter PIN',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    try {
      final staffDoc =
          await _firestore.collection('staff').doc(_selectedStaff).get();

      if (!staffDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: TextWidget(
                text: 'Staff member not found',
                fontSize: 14,
                fontFamily: 'Regular',
                color: Colors.white,
              ),
              backgroundColor: Colors.red[600],
            ),
          );
        }
        return;
      }

      final staffData = staffDoc.data() as Map<String, dynamic>;
      if (staffData['pin'] != _loginPinController.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: TextWidget(
                text: 'Incorrect PIN',
                fontSize: 14,
                fontFamily: 'Regular',
                color: Colors.white,
              ),
              backgroundColor: Colors.red[600],
            ),
          );
        }
        return;
      }

      // Save login status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_staff_logged_in', true);
      await prefs.setString('current_staff_name', staffData['name']);
      await prefs.setString('current_staff_id', _selectedStaff);

      if (mounted) {
        // Navigate to HomeScreen after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: 'Error logging in: $e',
              fontSize: 14,
              fontFamily: 'Regular',
              color: Colors.white,
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_staff_logged_in', false);
    await prefs.remove('current_staff_name');
    await prefs.remove('current_staff_id');

    _loginPinController.clear();

    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _currentStaffName = '';
        _currentStaffId = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return _buildMainScreen();
    } else {
      return _buildLoginScreen();
    }
  }

  Widget _buildMainScreen() {
    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: TextWidget(
          text: 'Kaffi Cafe POS',
          fontSize: 20,
          fontFamily: 'Bold',
          color: Colors.white,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white),
                const SizedBox(width: 8),
                TextWidget(
                  text: _currentStaffName,
                  fontSize: 16,
                  fontFamily: 'Medium',
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                ButtonWidget(
                  radius: 8,
                  color: Colors.red[600]!,
                  textColor: Colors.white,
                  label: 'Logout',
                  onPressed: _logout,
                  fontSize: 14,
                  width: 100,
                  height: 40,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
            SizedBox(height: 20),
            TextWidget(
              text: 'Staff Logged In Successfully',
              fontSize: 24,
              fontFamily: 'Bold',
              color: Colors.grey[800],
            ),
            SizedBox(height: 10),
            TextWidget(
              text: 'You can now access the POS system',
              fontSize: 18,
              fontFamily: 'Regular',
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_pin,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 20),
                TextWidget(
                  text: 'Staff Login',
                  fontSize: 28,
                  fontFamily: 'Bold',
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 30),
                if (_isCreatingStaff) ...[
                  _buildCreateStaffForm(),
                ] else ...[
                  _buildLoginForm(),
                ],
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isCreatingStaff = !_isCreatingStaff;
                    });
                  },
                  child: TextWidget(
                    text: _isCreatingStaff
                        ? 'Back to Login'
                        : 'Create New Staff Member',
                    fontSize: 16,
                    fontFamily: 'Medium',
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('staff').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return TextWidget(
                text: 'Error: ${snapshot.error}',
                fontSize: 14,
                fontFamily: 'Regular',
                color: Colors.red[600],
              );
            }

            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final staffList = snapshot.data!.docs;

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStaff.isEmpty && staffList.isNotEmpty
                          ? staffList.first.id
                          : _selectedStaff,
                      items: staffList.map((staff) {
                        final data = staff.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: staff.id,
                          child: TextWidget(
                            text: data['name'] ?? 'Unknown',
                            fontSize: 16,
                            fontFamily: 'Medium',
                            color: Colors.grey[800],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStaff = value ?? '';
                        });
                      },
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFieldWidget(
                  label: 'Enter 4-digit PIN',
                  controller: _loginPinController,
                  inputType: TextInputType.number,
                ),
                const SizedBox(height: 30),
                ButtonWidget(
                  radius: 12,
                  color: AppTheme.primaryColor,
                  textColor: Colors.white,
                  label: 'Login',
                  onPressed: _loginStaff,
                  fontSize: 18,
                  width: double.infinity,
                  height: 56,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCreateStaffForm() {
    return Column(
      children: [
        TextFieldWidget(
          label: 'Full Name',
          controller: _nameController,
          inputType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        TextFieldWidget(
          label: 'Position',
          controller: _positionController,
          inputType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        TextFieldWidget(
          label: '4-digit PIN',
          controller: _pinController,
          inputType: TextInputType.number,
        ),
        const SizedBox(height: 30),
        ButtonWidget(
          radius: 12,
          color: AppTheme.primaryColor,
          textColor: Colors.white,
          label: 'Create Staff Member',
          onPressed: _createStaff,
          fontSize: 18,
          width: double.infinity,
          height: 56,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _pinController.dispose();
    _loginPinController.dispose();
    super.dispose();
  }
}
