import 'package:flutter/material.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  File? _logoImage;
  Color _selectedColor = bayanihanBlue;

  // Business details controllers
  final TextEditingController _businessNameController =
      TextEditingController(text: 'Kaffi Cafe');
  final TextEditingController _descriptionController = TextEditingController(
      text:
          'A cozy cafe serving premium coffee and pastries in a welcoming atmosphere.');
  final TextEditingController _locationController =
      TextEditingController(text: 'Cagayan De Oro City');
  final TextEditingController _contactController =
      TextEditingController(text: '+639639520422');
  final TextEditingController _openHoursController =
      TextEditingController(text: 'Mon-Sun, 7AM-9PM');

  // Image picker for logo
  Future<void> _pickLogoImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _logoImage = File(pickedFile.path);
      });
    }
  }

  // Show color picker dialog
  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: TextWidget(
          text: 'Select Primary Color',
          fontSize: 20,
          fontFamily: 'Bold',
          color: bayanihanBlue,
          isBold: true,
        ),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              if (mounted) {
                setState(() {
                  _selectedColor = color;
                });
              }
            },
            availableColors: [
              bayanihanBlue,
              Colors.red,
              Colors.green,
              Colors.blue,
              Colors.purple,
              Colors.orange,
              Colors.teal,
              Colors.pink,
              Colors.cyan,
              Colors.amber,
            ],
            layoutBuilder: (context, colors, picker) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((color) => picker(color)).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Cancel',
              fontSize: 16,
              fontFamily: 'Medium',
              color: bayanihanBlue,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              print('Selected color: $_selectedColor');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: bayanihanBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: TextWidget(
              text: 'Save',
              fontSize: 16,
              fontFamily: 'Medium',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Save all settings
  void _saveSettings() {
    print('Saving Settings:');
    print('Logo: ${_logoImage?.path ?? "No logo selected"}');
    print('Color: $_selectedColor');
    print('Business Name: ${_businessNameController.text}');
    print('Description: ${_descriptionController.text}');
    print('Location: ${_locationController.text}');
    print('Contact: ${_contactController.text}');
    print('Open Hours: ${_openHoursController.text}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TextWidget(
          text: 'Settings saved successfully!',
          fontSize: 14,
          fontFamily: 'Medium',
          color: Colors.white,
        ),
        backgroundColor: bayanihanBlue,
      ),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _openHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: bayanihanBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        title: TextWidget(
          text: 'Settings',
          fontSize: 24,
          fontFamily: 'Bold',
          color: Colors.white,
          isBold: true,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Logo and Color Palette
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo Section
                    TextWidget(
                      text: 'App Logo',
                      fontSize: 22,
                      fontFamily: 'Bold',
                      color: bayanihanBlue,
                      isBold: true,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: bayanihanBlue.withOpacity(0.3)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              bayanihanBlue.withOpacity(0.1),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              ),
                              child: _logoImage == null
                                  ? Container(
                                      key: const ValueKey('placeholder'),
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                bayanihanBlue.withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: TextWidget(
                                          text: 'Logo\nPlaceholder',
                                          fontSize: 18,
                                          fontFamily: 'Medium',
                                          color: Colors.grey[600],
                                          align: TextAlign.center,
                                        ),
                                      ),
                                    )
                                  : ClipRRect(
                                      key: const ValueKey('logo'),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(
                                        _logoImage!,
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _pickLogoImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bayanihanBlue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                elevation: 3,
                                shadowColor: bayanihanBlue.withOpacity(0.5),
                              ),
                              child: TextWidget(
                                text: 'Select Logo',
                                fontSize: 16,
                                fontFamily: 'Medium',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Color Palette Section
                    TextWidget(
                      text: 'Color Palette',
                      fontSize: 22,
                      fontFamily: 'Bold',
                      color: bayanihanBlue,
                      isBold: true,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: bayanihanBlue.withOpacity(0.3)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              bayanihanBlue.withOpacity(0.1),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _selectedColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: bayanihanBlue.withOpacity(0.4),
                                    width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _selectedColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: TextWidget(
                                text: 'Primary Color',
                                fontSize: 18,
                                fontFamily: 'Medium',
                                color: Colors.grey[800],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _showColorPickerDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bayanihanBlue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                elevation: 3,
                                shadowColor: bayanihanBlue.withOpacity(0.5),
                              ),
                              child: TextWidget(
                                text: 'Choose Color',
                                fontSize: 16,
                                fontFamily: 'Medium',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right Column: Business Details
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Business Details',
                      fontSize: 22,
                      fontFamily: 'Bold',
                      color: bayanihanBlue,
                      isBold: true,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: bayanihanBlue.withOpacity(0.3)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              bayanihanBlue.withOpacity(0.1),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Business Name
                            TextWidget(
                              text: 'Business Name',
                              fontSize: 18,
                              fontFamily: 'Medium',
                              color: Colors.grey[800],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _businessNameController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Regular',
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Description
                            TextWidget(
                              text: 'Description',
                              fontSize: 18,
                              fontFamily: 'Medium',
                              color: Colors.grey[800],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _descriptionController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Regular',
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Location
                            TextWidget(
                              text: 'Location',
                              fontSize: 18,
                              fontFamily: 'Medium',
                              color: Colors.grey[800],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Regular',
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Contact Details
                            TextWidget(
                              text: 'Contact Details',
                              fontSize: 18,
                              fontFamily: 'Medium',
                              color: Colors.grey[800],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _contactController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Regular',
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Open Hours
                            TextWidget(
                              text: 'Open Hours',
                              fontSize: 18,
                              fontFamily: 'Medium',
                              color: Colors.grey[800],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _openHoursController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: bayanihanBlue, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Regular',
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Floating Save Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSettings,
        backgroundColor: bayanihanBlue,
        elevation: 4,
        icon: const Icon(Icons.save, color: Colors.white),
        label: TextWidget(
          text: 'Save All Settings',
          fontSize: 16,
          fontFamily: 'Medium',
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
