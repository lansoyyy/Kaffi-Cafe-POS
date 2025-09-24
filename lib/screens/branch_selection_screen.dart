import 'package:flutter/material.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/utils/branch_service.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';

class BranchSelectionScreen extends StatefulWidget {
  const BranchSelectionScreen({super.key});

  @override
  State<BranchSelectionScreen> createState() => _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends State<BranchSelectionScreen> {
  String? _selectedBranch;

  final List<String> _branches = [
    'Kaffi Cafe - Eloisa St',
    'Kaffi Cafe - P.Noval',
  ];

  @override
  void initState() {
    super.initState();
    // Check if a branch is already selected
    _selectedBranch = BranchService.getSelectedBranch();
  }

  void _selectBranch(String branch) {
    setState(() {
      _selectedBranch = branch;
    });
  }

  void _confirmSelection() async {
    if (_selectedBranch != null) {
      // Save the selected branch to storage
      await BranchService.saveSelectedBranch(_selectedBranch!);

      // Navigate to the staff login screen
      Navigator.pushReplacementNamed(context, '/staff');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Please select a branch',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Icons.store,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 20),
                TextWidget(
                  text: 'Select Branch',
                  fontSize: 28,
                  fontFamily: 'Bold',
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 10),
                TextWidget(
                  text: 'Please select your branch location',
                  fontSize: 16,
                  fontFamily: 'Regular',
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 30),
                ..._branches.map((branch) {
                  final isSelected = _selectedBranch == branch;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => _selectBranch(branch),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.storefront,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[600],
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextWidget(
                                text: branch,
                                fontSize: 18,
                                fontFamily: 'Medium',
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey[800],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.primaryColor,
                                size: 28,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 30),
                ButtonWidget(
                  radius: 12,
                  color: AppTheme.primaryColor,
                  textColor: Colors.white,
                  label: 'Continue',
                  onPressed: _confirmSelection,
                  fontSize: 18,
                  width: double.infinity,
                  height: 56,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
