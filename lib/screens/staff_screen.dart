import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/utils/branch_service.dart';
import 'package:kaffi_cafe_pos/utils/role_service.dart';
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
  final TextEditingController _superAdminUsernameController =
      TextEditingController();
  final TextEditingController _superAdminPinController =
      TextEditingController();

  String _selectedStaff = '';
  bool _isCreatingStaff = false;
  bool _isLoggedIn = false;
  String _currentStaffName = '';
  String _currentStaffId = '';
  String? _currentBranch;
  bool _isSuperAdminLogin = false;
  bool _isManagingStaff = false;
  String _editingStaffId = '';
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editPositionController = TextEditingController();
  final TextEditingController _editPinController = TextEditingController();

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
    final currentBranch = BranchService.getSelectedBranch();
    final isSuperAdmin = await RoleService.isSuperAdmin();

    if (!isSuperAdmin && isLoggedIn) {
      // Redirect to home screen if not Super Admin
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _currentStaffName = staffName;
        _currentStaffId = staffId;
        _currentBranch = currentBranch;
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
        'role': RoleService.staffRole,
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

  Future<void> _updateStaff() async {
    if (_editNameController.text.isEmpty ||
        _editPositionController.text.isEmpty ||
        _editPinController.text.isEmpty) {
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
    if (_editPinController.text.length != 4 ||
        int.tryParse(_editPinController.text) == null) {
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
      await _firestore.collection('staff').doc(_editingStaffId).update({
        'name': _editNameController.text,
        'position': _editPositionController.text,
        'pin': _editPinController.text,
      });

      // Clear form and reset editing state
      _editNameController.clear();
      _editPositionController.clear();
      _editPinController.clear();
      _editingStaffId = '';

      if (mounted) {
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: 'Staff member updated successfully',
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
              text: 'Error updating staff: $e',
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

  Future<void> _deleteStaff(String staffId, String staffName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: TextWidget(
          text: 'Confirm Deletion',
          fontSize: 18,
          fontFamily: 'Bold',
          color: Colors.grey[800],
        ),
        content: TextWidget(
          text:
              'Are you sure you want to delete $staffName? This action cannot be undone.',
          fontSize: 16,
          fontFamily: 'Regular',
          color: Colors.grey[700],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: TextWidget(
              text: 'Cancel',
              fontSize: 16,
              fontFamily: 'Medium',
              color: AppTheme.primaryColor,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: TextWidget(
              text: 'Delete',
              fontSize: 16,
              fontFamily: 'Medium',
              color: Colors.red[600],
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('staff').doc(staffId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: 'Staff member deleted successfully',
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
              text: 'Error deleting staff: $e',
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
      await RoleService.setUserRole(staffData['role'] ?? RoleService.staffRole);

      // Update branch isOnline status
      final currentBranch = BranchService.getSelectedBranch();
      if (currentBranch != null) {
        await _firestore
            .collection('branches')
            .doc(currentBranch == 'Kaffi Cafe - Eloisa St'
                ? 'branch1'
                : 'branch2')
            .update({
          'isOnline': true,
        });
      }

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

  Future<void> _loginSuperAdmin() async {
    if (_superAdminUsernameController.text.isEmpty ||
        _superAdminPinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Please enter Super Admin credentials',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    if (RoleService.isSuperAdminLogin(
        _superAdminUsernameController.text, _superAdminPinController.text)) {
      // Save Super Admin login status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_staff_logged_in', true);
      await prefs.setString('current_staff_name', 'Super Admin');
      await prefs.setString('current_staff_id', 'super_admin');
      await RoleService.setUserRole(RoleService.superAdminRole);

      // Update branch isOnline status
      final currentBranch = BranchService.getSelectedBranch();
      if (currentBranch != null) {
        await _firestore
            .collection('branches')
            .doc(currentBranch == 'Kaffi Cafe - Eloisa St'
                ? 'branch1'
                : 'branch2')
            .update({
          'isOnline': true,
        });
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: 'Invalid Super Admin credentials',
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
    await RoleService.clearUserRole();

    // Update branch isOnline status
    final currentBranch = BranchService.getSelectedBranch();
    if (currentBranch != null) {
      await _firestore
          .collection('branches')
          .doc(
              currentBranch == 'Kaffi Cafe - Eloisa St' ? 'branch1' : 'branch2')
          .update({
        'isOnline': false,
      });
    }

    _loginPinController.clear();
    _superAdminUsernameController.clear();
    _superAdminPinController.clear();

    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _currentStaffName = '';
        _currentStaffId = '';
        _isManagingStaff = false;
      });
    }
  }

  Future<void> _changeBranch() async {
    // Update current branch isOnline status to false
    final currentBranch = BranchService.getSelectedBranch();
    if (currentBranch != null) {
      await _firestore
          .collection('branches')
          .doc(
              currentBranch == 'Kaffi Cafe - Eloisa St' ? 'branch1' : 'branch2')
          .update({
        'isOnline': false,
      });
    }

    await BranchService.clearSelectedBranch();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/branch');
    }
  }

  void _startEditingStaff(Map<String, dynamic> staffData, String staffId) {
    setState(() {
      _editingStaffId = staffId;
      _editNameController.text = staffData['name'] ?? '';
      _editPositionController.text = staffData['position'] ?? '';
      _editPinController.text = staffData['pin'] ?? '';
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingStaffId = '';
      _editNameController.clear();
      _editPositionController.clear();
      _editPinController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return _isManagingStaff
          ? _buildStaffManagementScreen()
          : _buildMainScreen();
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
                const Icon(Icons.storefront, color: Colors.white),
                const SizedBox(width: 8),
                TextWidget(
                  text: _currentBranch ?? 'No Branch',
                  fontSize: 16,
                  fontFamily: 'Medium',
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
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
                  color: Colors.orange[600]!,
                  textColor: Colors.white,
                  label: 'Change Branch',
                  onPressed: _changeBranch,
                  fontSize: 14,
                  width: 120,
                  height: 40,
                ),
                const SizedBox(width: 8),
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
            SizedBox(height: 30),
            if (_currentStaffName == 'Super Admin') ...[
              ButtonWidget(
                radius: 12,
                color: AppTheme.primaryColor,
                textColor: Colors.white,
                label: 'Manage Staff Accounts',
                onPressed: () {
                  setState(() {
                    _isManagingStaff = true;
                  });
                },
                fontSize: 18,
                width: 250,
                height: 56,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStaffManagementScreen() {
    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: TextWidget(
          text: 'Staff Management',
          fontSize: 20,
          fontFamily: 'Bold',
          color: Colors.white,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.storefront, color: Colors.white),
                const SizedBox(width: 8),
                TextWidget(
                  text: _currentBranch ?? 'No Branch',
                  fontSize: 16,
                  fontFamily: 'Medium',
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
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
                  color: Colors.orange[600]!,
                  textColor: Colors.white,
                  label: 'Change Branch',
                  onPressed: _changeBranch,
                  fontSize: 14,
                  width: 120,
                  height: 40,
                ),
                const SizedBox(width: 8),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  text: 'Staff Accounts',
                  fontSize: 24,
                  fontFamily: 'Bold',
                  color: Colors.grey[800],
                ),
                ButtonWidget(
                  radius: 8,
                  color: AppTheme.primaryColor,
                  textColor: Colors.white,
                  label: 'Back to Dashboard',
                  onPressed: () {
                    setState(() {
                      _isManagingStaff = false;
                    });
                  },
                  fontSize: 14,
                  width: 150,
                  height: 40,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextWidget(
                              text: 'Name',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextWidget(
                              text: 'Position',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: TextWidget(
                              text: 'PIN',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: TextWidget(
                              text: 'Actions',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('staff').snapshots(),
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
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final staffList = snapshot.data!.docs;

                          if (staffList.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  TextWidget(
                                    text: 'No staff members found',
                                    fontSize: 18,
                                    fontFamily: 'Medium',
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(height: 8),
                                  TextWidget(
                                    text: 'Add staff members to get started',
                                    fontSize: 14,
                                    fontFamily: 'Regular',
                                    color: Colors.grey[500],
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: staffList.length,
                            itemBuilder: (context, index) {
                              final staff = staffList[index];
                              final staffData =
                                  staff.data() as Map<String, dynamic>;
                              final staffId = staff.id;

                              if (_editingStaffId == staffId) {
                                return _buildEditStaffRow(staffData, staffId);
                              }

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: index % 2 == 0
                                      ? Colors.grey[50]
                                      : Colors.white,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: TextWidget(
                                        text: staffData['name'] ?? 'Unknown',
                                        fontSize: 16,
                                        fontFamily: 'Medium',
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: TextWidget(
                                        text:
                                            staffData['position'] ?? 'Unknown',
                                        fontSize: 16,
                                        fontFamily: 'Regular',
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: TextWidget(
                                        text: '****', // Hide PIN for security
                                        fontSize: 16,
                                        fontFamily: 'Regular',
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            onPressed: () => _startEditingStaff(
                                                staffData, staffId),
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.blue[600],
                                              size: 20,
                                            ),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            onPressed: () => _deleteStaff(
                                                staffId,
                                                staffData['name'] ?? 'Unknown'),
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red[600],
                                              size: 20,
                                            ),
                                            tooltip: 'Delete',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isCreatingStaff
                ? _buildCreateStaffForm()
                : ButtonWidget(
                    radius: 12,
                    color: AppTheme.primaryColor,
                    textColor: Colors.white,
                    label: 'Add New Staff Member',
                    onPressed: () {
                      setState(() {
                        _isCreatingStaff = true;
                      });
                    },
                    fontSize: 18,
                    width: double.infinity,
                    height: 56,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditStaffRow(Map<String, dynamic> staffData, String staffId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFieldWidget(
              label: 'Name',
              controller: _editNameController,
              inputType: TextInputType.text,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: TextFieldWidget(
              label: 'Position',
              controller: _editPositionController,
              inputType: TextInputType.text,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: TextFieldWidget(
              label: 'PIN',
              controller: _editPinController,
              inputType: TextInputType.number,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                ButtonWidget(
                  radius: 8,
                  color: Colors.green[600]!,
                  textColor: Colors.white,
                  label: 'Save',
                  onPressed: _updateStaff,
                  fontSize: 14,
                  width: 60,
                  height: 36,
                ),
                SizedBox(width: 8),
                ButtonWidget(
                  radius: 8,
                  color: Colors.grey[600]!,
                  textColor: Colors.white,
                  label: 'Cancel',
                  onPressed: _cancelEditing,
                  fontSize: 14,
                  width: 60,
                  height: 36,
                ),
              ],
            ),
          ),
        ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    const SizedBox(width: 20),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSuperAdminLogin = !_isSuperAdminLogin;
                          _isCreatingStaff = false;
                        });
                      },
                      child: TextWidget(
                        text: _isSuperAdminLogin
                            ? 'Staff Login'
                            : 'Super Admin Login',
                        fontSize: 16,
                        fontFamily: 'Medium',
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    if (_isSuperAdminLogin) {
      return _buildSuperAdminLoginForm();
    }

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

  Widget _buildSuperAdminLoginForm() {
    return Column(
      children: [
        TextFieldWidget(
          label: 'Super Admin Username',
          controller: _superAdminUsernameController,
          inputType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        TextFieldWidget(
          label: 'Super Admin PIN',
          controller: _superAdminPinController,
          inputType: TextInputType.number,
        ),
        const SizedBox(height: 30),
        ButtonWidget(
          radius: 12,
          color: Colors.red,
          textColor: Colors.white,
          label: 'Login as Super Admin',
          onPressed: _loginSuperAdmin,
          fontSize: 18,
          width: double.infinity,
          height: 56,
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
        Row(
          children: [
            Expanded(
              child: ButtonWidget(
                radius: 12,
                color: AppTheme.primaryColor,
                textColor: Colors.white,
                label: 'Create Staff Member',
                onPressed: _createStaff,
                fontSize: 18,
                width: double.infinity,
                height: 56,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ButtonWidget(
                radius: 12,
                color: Colors.grey[600]!,
                textColor: Colors.white,
                label: 'Cancel',
                onPressed: () {
                  setState(() {
                    _isCreatingStaff = false;
                    _nameController.clear();
                    _positionController.clear();
                    _pinController.clear();
                  });
                },
                fontSize: 18,
                width: double.infinity,
                height: 56,
              ),
            ),
          ],
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
    _superAdminUsernameController.dispose();
    _superAdminPinController.dispose();
    _editNameController.dispose();
    _editPositionController.dispose();
    _editPinController.dispose();
    super.dispose();
  }
}
