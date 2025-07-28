import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  File? _logoImage;
  String? _logoUrl;
  Color _selectedColor = AppTheme.primaryColor;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Business details controllers
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _openHoursController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load settings from Firestore
  Future<void> _loadSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('business').get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _businessNameController.text = data['businessName'] ?? 'Kaffi Cafe';
          _descriptionController.text = data['description'] ??
              'A cozy cafe serving premium coffee and pastries in a welcoming atmosphere.';
          _locationController.text = data['location'] ?? 'Cagayan De Oro City';
          _contactController.text = data['contact'] ?? '+639639520422';
          _openHoursController.text = data['openHours'] ?? 'Mon-Sun, 7AM-9PM';
          _logoUrl = data['logoUrl'];
          _selectedColor =
              Color(data['primaryColor'] ?? AppTheme.primaryColor.value);
          // Update the app theme with the loaded color
          AppTheme.updatePrimaryColor(_selectedColor);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error loading settings: $e',
            fontSize: 14,
            fontFamily: 'Medium',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  // Pick logo image
  Future<void> _pickLogoImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _logoImage = File(pickedFile.path);
      });
    }
  }

  // Upload logo to Firebase Storage
  Future<String?> _uploadLogoImage() async {
    if (_logoImage == null) return _logoUrl;
    try {
      final ref = _storage.ref().child('logos/business_logo.png');
      await ref.putFile(_logoImage!);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error uploading logo: $e',
            fontSize: 14,
            fontFamily: 'Medium',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return null;
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
          color: AppTheme.primaryColor,
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
              AppTheme.primaryColor,
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
              color: AppTheme.primaryColor,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
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

  // Save all settings to Firestore
  Future<void> _saveSettings() async {
    if (_businessNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _contactController.text.isEmpty ||
        _openHoursController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Please fill in all fields',
            fontSize: 14,
            fontFamily: 'Medium',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }
    try {
      final logoUrl = await _uploadLogoImage();
      await _firestore.collection('settings').doc('business').set({
        'businessName': _businessNameController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'contact': _contactController.text,
        'openHours': _openHoursController.text,
        'logoUrl': logoUrl,
        'primaryColor': _selectedColor.value,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the app theme with the new color
      AppTheme.updatePrimaryColor(_selectedColor);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Settings saved successfully!',
            fontSize: 14,
            fontFamily: 'Medium',
            color: Colors.white,
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error saving settings: $e',
            fontSize: 14,
            fontFamily: 'Medium',
            color: Colors.white,
          ),
          backgroundColor: Colors.red[600],
        ),
      );
    }
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
        backgroundColor: AppTheme.primaryColor,
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
        decoration: const BoxDecoration(color: Colors.white),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'App Logo',
                      fontSize: 22,
                      fontFamily: 'Bold',
                      color: AppTheme.primaryColor,
                      isBold: true,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              AppTheme.primaryColor.withOpacity(0.1),
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
                              child: _logoImage != null
                                  ? ClipRRect(
                                      key: const ValueKey('logo'),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(
                                        _logoImage!,
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _logoUrl != null
                                      ? ClipRRect(
                                          key: const ValueKey('logoUrl'),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Image.network(
                                            _logoUrl!,
                                            width: 200,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              width: 200,
                                              height: 200,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.primaryColor
                                                        .withOpacity(0.4),
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
                                            ),
                                          ),
                                        )
                                      : Container(
                                          key: const ValueKey('placeholder'),
                                          width: 200,
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryColor
                                                    .withOpacity(0.4),
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
                                        ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _pickLogoImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                elevation: 3,
                                shadowColor:
                                    AppTheme.primaryColor.withOpacity(0.5),
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
                    TextWidget(
                      text: 'Color Palette',
                      fontSize: 22,
                      fontFamily: 'Bold',
                      color: AppTheme.primaryColor,
                      isBold: true,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              AppTheme.primaryColor.withOpacity(0.1),
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
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.4),
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
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                elevation: 3,
                                shadowColor:
                                    AppTheme.primaryColor.withOpacity(0.5),
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
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Business Details',
                      fontSize: 22,
                      fontFamily: 'Bold',
                      color: AppTheme.primaryColor,
                      isBold: true,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              AppTheme.primaryColor.withOpacity(0.1),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppTheme.primaryColor, width: 2),
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
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppTheme.primaryColor, width: 2),
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
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppTheme.primaryColor, width: 2),
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
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppTheme.primaryColor, width: 2),
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
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppTheme.primaryColor, width: 2),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSettings,
        backgroundColor: AppTheme.primaryColor,
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
