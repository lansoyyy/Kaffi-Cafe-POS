import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/utils/app_theme.dart';
import 'package:kaffi_cafe_pos/utils/branch_service.dart';
import 'package:kaffi_cafe_pos/widgets/button_widget.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentBranch;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String? _selectedTableId;
  int _numberOfGuests = 1;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  List<String> _availableTimeSlots = [];
  bool _isLoading = true;
  Map<String, bool> _tableAvailability = {};

  // Table management state
  bool _isTableManagementMode = false;
  Map<String, bool> _tableEnabledStatus = {};
  Map<String, dynamic> _tableReservations = {};
  Timer? _reservationExpiryTimer;

  @override
  void initState() {
    super.initState();
    _initializeReservation();
  }

  // Initialize reservation data
  Future<void> _initializeReservation() async {
    setState(() {
      _isLoading = true;
    });

    // Get current branch
    _currentBranch = BranchService.getSelectedBranch();

    // Initialize table availability and enabled status
    for (var table in _tables) {
      _tableAvailability[table['id']] = true;
      _tableEnabledStatus[table['id']] = true;
    }

    // Generate available time slots based on operating hours
    _generateTimeSlots();

    // Start reservation expiry monitoring
    _startReservationExpiryMonitoring();

    setState(() {
      _isLoading = false;
    });
  }

  // Start monitoring for reservation expiry
  void _startReservationExpiryMonitoring() {
    _reservationExpiryTimer?.cancel();
    _reservationExpiryTimer =
        Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkReservationExpiry();
    });
  }

  // Check for expired reservations and update table status
  Future<void> _checkReservationExpiry() async {
    try {
      final now = DateTime.now();
      final QuerySnapshot snapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: 'confirmed')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final reservation = data['reservation'] as Map<String, dynamic>;

        // Parse reservation date and time
        final String dateStr = reservation['date'];
        final String timeStr = reservation['time'];

        // Convert to DateTime for comparison
        final List<String> dateParts = dateStr.split('/');
        final DateTime reservationDate = DateTime(
          int.parse(dateParts[2]), // year
          int.parse(dateParts[1]), // month
          int.parse(dateParts[0]), // day
        );

        // Parse time (format: "7:00 AM" or "7:00 PM")
        final List<String> timeParts = timeStr.split(' ');
        final List<String> hourMinute = timeParts[0].split(':');
        int hour = int.parse(hourMinute[0]);
        final int minute = int.parse(hourMinute[1]);

        // Convert to 24-hour format
        if (timeParts[1] == 'PM' && hour != 12) {
          hour += 12;
        } else if (timeParts[1] == 'AM' && hour == 12) {
          hour = 0;
        }

        final DateTime reservationDateTime = DateTime(
          reservationDate.year,
          reservationDate.month,
          reservationDate.day,
          hour,
          minute,
        );

        // Check if reservation is more than 1 hour old
        if (now.difference(reservationDateTime).inHours >= 1) {
          // Update reservation status to expired
          await _firestore.collection('reservations').doc(doc.id).update({
            'status': 'expired',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error checking reservation expiry: $e');
    }
  }

  // Get current table status
  String _getTableStatus(String tableId) {
    if (!_tableEnabledStatus[tableId]!) {
      return 'Disabled';
    }

    // Check if table has active reservation
    if (_tableReservations.containsKey(tableId)) {
      final reservation = _tableReservations[tableId];
      if (reservation['status'] == 'confirmed') {
        return 'Reserved';
      }
    }

    return 'Available';
  }

  // Toggle table enabled/disabled status
  Future<void> _toggleTableStatus(String tableId) async {
    try {
      final newStatus = !_tableEnabledStatus[tableId]!;

      // Update local state
      setState(() {
        _tableEnabledStatus[tableId] = newStatus;
      });

      // Update in Firestore
      await _firestore.collection('tables').doc(tableId).set({
        'enabled': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text:
                'Table ${_tables.firstWhere((t) => t['id'] == tableId)['name']} ${newStatus ? 'enabled' : 'disabled'}',
            fontSize: 14,
            color: plainWhite,
            fontFamily: 'Regular',
          ),
          backgroundColor: newStatus ? AppTheme.primaryColor : festiveRed,
        ),
      );
    } catch (e) {
      // Revert on error
      setState(() {
        _tableEnabledStatus[tableId] = !_tableEnabledStatus[tableId]!;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error updating table status: $e',
            fontSize: 14,
            color: plainWhite,
            fontFamily: 'Regular',
          ),
          backgroundColor: festiveRed,
        ),
      );
    }
  }

  // Load table reservations for today
  Future<void> _loadTableReservations() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final QuerySnapshot snapshot = await _firestore
          .collection('reservations')
          .where('date', isEqualTo: today)
          .where('status', whereIn: ['confirmed', 'checked_in']).get();

      Map<String, dynamic> reservations = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final tableId = data['tableId'] as String;

        reservations[tableId] = {
          ...data,
          'docId': doc.id,
        };
      }

      setState(() {
        _tableReservations = reservations;
      });
    } catch (e) {
      print('Error loading table reservations: $e');
    }
  }

  // Tables configuration (3 tables with 2 seats, 2 tables with 4 seats)
  final List<Map<String, dynamic>> _tables = [
    {'id': 'table1', 'name': 'Table 1', 'capacity': 2},
    {'id': 'table2', 'name': 'Table 2', 'capacity': 2},
    {'id': 'table3', 'name': 'Table 3', 'capacity': 2},
    {'id': 'table4', 'name': 'Table 4', 'capacity': 4},
    {'id': 'table5', 'name': 'Table 5', 'capacity': 4},
  ];

  // Generate available time slots based on operating hours (7:00 AM - 11:00 PM)
  void _generateTimeSlots() {
    final now = DateTime.now();
    final List<String> slots = [];

    // Operating hours: 7:00 AM to 11:00 PM
    // Last slot: 10:00-10:59 PM
    for (int hour = 7; hour <= 22; hour++) {
      // Skip past hours for today
      if (_selectedDate.day == now.day &&
          _selectedDate.month == now.month &&
          _selectedDate.year == now.year &&
          hour <= now.hour) {
        continue;
      }

      // Format hour for 12-hour clock
      String period = hour < 12 ? 'AM' : 'PM';
      int displayHour = hour <= 12 ? hour : hour - 12;
      if (displayHour == 0) displayHour = 12;

      String timeSlot = '$displayHour:00 $period';
      slots.add(timeSlot);
    }

    setState(() {
      _availableTimeSlots = slots;
    });
  }

  // Check if a table is available for a specific date and time
  Future<bool> _checkTableAvailability(
      String tableId, DateTime date, String time) async {
    try {
      // Query reservations for the same date, time, and table
      final QuerySnapshot snapshot = await _firestore
          .collection('reservations')
          .where('tableId', isEqualTo: tableId)
          .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(date))
          .where('time', isEqualTo: time)
          .where('status', whereIn: ['confirmed', 'checked_in']).get();

      // If no reservations found, table is available
      return snapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking table availability: $e');
      return false;
    }
  }

  // Update table availability based on selected date and time
  Future<void> _updateTableAvailability() async {
    if (_selectedTime == null) return;

    setState(() {
      _isLoading = true;
    });

    // Check availability for each table
    for (var table in _tables) {
      bool isAvailable = await _checkTableAvailability(
        table['id'],
        _selectedDate,
        _selectedTime!,
      );

      setState(() {
        _tableAvailability[table['id']] = isAvailable;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    _reservationExpiryTimer?.cancel();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: plainWhite,
              surface: plainWhite,
              onSurface: textBlack,
            ),
            dialogBackgroundColor: plainWhite,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset time when date changes
        _selectedTableId = null; // Reset table when date changes
        _generateTimeSlots(); // Regenerate time slots for new date
      });
    }
  }

  void _showReservationDetails(
      BuildContext context, Map<String, dynamic> table) {
    final reservation = table['reservation'];
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.018;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: plainWhite,
        title: TextWidget(
          text: 'Occupied',
          fontSize: fontSize + 4,
          color: textBlack,
          isBold: true,
          fontFamily: 'Bold',
        ),
        content: reservation == null
            ? TextWidget(
                text: 'No reservation details available.',
                fontSize: fontSize + 2,
                color: charcoalGray,
                fontFamily: 'Regular',
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Customer: ${reservation['userEmail']}',
                      fontSize: fontSize + 2,
                      color: textBlack,
                      fontFamily: 'Regular',
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text: 'Date: ${reservation['date']}',
                      fontSize: fontSize + 2,
                      color: textBlack,
                      fontFamily: 'Regular',
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text: 'Time: ${reservation['time']}',
                      fontSize: fontSize + 2,
                      color: textBlack,
                      fontFamily: 'Regular',
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text: 'Guests: ${reservation['guests']}',
                      fontSize: fontSize + 2,
                      color: textBlack,
                      fontFamily: 'Regular',
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text: 'Order: ${reservation['order']}',
                      fontSize: fontSize + 2,
                      color: textBlack,
                      fontFamily: 'Regular',
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text: 'Status: ${reservation['status']}',
                      fontSize: fontSize + 2,
                      color: reservation['status'] == 'confirmed'
                          ? AppTheme.primaryColor
                          : festiveRed,
                      fontFamily: 'Regular',
                    ),
                  ],
                ),
              ),
        actions: [
          if (reservation != null)
            ButtonWidget(
              label:
                  reservation['status'] == 'confirmed' ? 'Cancel' : 'Confirm',
              onPressed: () async {
                try {
                  final newStatus = reservation['status'] == 'confirmed'
                      ? 'cancelled'
                      : 'confirmed';
                  await _firestore
                      .collection('reservations')
                      .doc(table['docId'])
                      .update({
                    'status': newStatus,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: TextWidget(
                        text:
                            'Reservation ${newStatus.toLowerCase()} successfully',
                        fontSize: fontSize,
                        color: plainWhite,
                        fontFamily: 'Regular',
                      ),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: TextWidget(
                        text: 'Error updating reservation: $e',
                        fontSize: fontSize,
                        color: plainWhite,
                        fontFamily: 'Regular',
                      ),
                      backgroundColor: festiveRed,
                    ),
                  );
                }
              },
              color: reservation['status'] == 'confirmed'
                  ? festiveRed
                  : AppTheme.primaryColor,
              textColor: plainWhite,
              fontSize: fontSize + 1,
              height: 45,
              width: 100,
              radius: 10,
            ),
          ButtonWidget(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            color: ashGray,
            textColor: textBlack,
            fontSize: fontSize + 1,
            height: 45,
            width: 100,
            radius: 10,
          ),
        ],
      ),
    );
  }

  void _showCreateReservationDialog(BuildContext context) {
    if (_selectedTime == null || _selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Please select a time and table',
            fontSize: 14,
            color: plainWhite,
            fontFamily: 'Regular',
          ),
          backgroundColor: festiveRed,
        ),
      );
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.018;

    _nameController.clear();
    _orderController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: plainWhite,
        title: TextWidget(
          text:
              'Create Reservation for ${_tables.firstWhere((t) => t['id'] == _selectedTableId)['name']}',
          fontSize: fontSize + 4,
          color: textBlack,
          isBold: true,
          fontFamily: 'Bold',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Customer Name',
                  labelStyle: TextStyle(
                    fontSize: fontSize + 2,
                    fontFamily: 'Regular',
                    color: charcoalGray,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
                style: TextStyle(
                  fontSize: fontSize + 2,
                  fontFamily: 'Regular',
                  color: textBlack,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _orderController,
                decoration: InputDecoration(
                  labelText: 'Order Details',
                  labelStyle: TextStyle(
                    fontSize: fontSize + 2,
                    fontFamily: 'Regular',
                    color: charcoalGray,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
                style: TextStyle(
                  fontSize: fontSize + 2,
                  fontFamily: 'Regular',
                  color: textBlack,
                ),
              ),
              const SizedBox(height: 12),
              TextWidget(
                text: 'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                fontSize: fontSize + 2,
                color: textBlack,
                fontFamily: 'Regular',
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'Time: $_selectedTime',
                fontSize: fontSize + 2,
                color: textBlack,
                fontFamily: 'Regular',
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'Guests: $_numberOfGuests',
                fontSize: fontSize + 2,
                color: textBlack,
                fontFamily: 'Regular',
              ),
            ],
          ),
        ),
        actions: [
          ButtonWidget(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
            color: ashGray,
            textColor: textBlack,
            fontSize: fontSize + 1,
            height: 45,
            width: 100,
            radius: 10,
          ),
          ButtonWidget(
            label: 'Confirm',
            onPressed: () async {
              if (_nameController.text.isEmpty ||
                  _orderController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Please fill in all fields',
                      fontSize: fontSize,
                      color: plainWhite,
                      fontFamily: 'Regular',
                    ),
                    backgroundColor: festiveRed,
                  ),
                );
                return;
              }
              try {
                final selectedTable =
                    _tables.firstWhere((t) => t['id'] == _selectedTableId);
                await _firestore.collection('reservations').add({
                  'tableId': _selectedTableId,
                  'tableName': selectedTable['name'],
                  'capacity': selectedTable['capacity'],

                  'name': _nameController.text,
                  'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
                  'time': _selectedTime,
                  'guests': _numberOfGuests,
                  'order': _orderController.text,
                  'status': 'confirmed',
                  'source': 'POS', // Indicates reservation made via POS
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.of(context).pop();
                setState(() {
                  _selectedTime = null;
                  _selectedTableId = null;
                  _nameController.clear();
                  _orderController.clear();
                  _numberOfGuests = 1;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text:
                          'Reservation confirmed for ${_tables.firstWhere((t) => t['id'] == _selectedTableId)['name']} at $_selectedTime',
                      fontSize: fontSize,
                      color: plainWhite,
                      fontFamily: 'Regular',
                    ),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Error creating reservation: $e',
                      fontSize: fontSize,
                      color: plainWhite,
                      fontFamily: 'Regular',
                    ),
                    backgroundColor: festiveRed,
                  ),
                );
              }
            },
            color: AppTheme.primaryColor,
            textColor: plainWhite,
            fontSize: fontSize + 1,
            height: 45,
            width: 100,
            radius: 10,
          ),
        ],
      ),
    );
  }

  void _showEditReservationDialog(
      BuildContext context, Map<String, dynamic> table) {
    final reservation = table['reservation'];
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.018;

    _nameController.text = reservation['name'];
    _orderController.text = reservation['order'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: plainWhite,
        title: TextWidget(
          text: 'Edit Reservation for ${table['name']}',
          fontSize: fontSize + 4,
          color: textBlack,
          isBold: true,
          fontFamily: 'Bold',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Customer Name',
                  labelStyle: TextStyle(
                    fontSize: fontSize + 2,
                    fontFamily: 'Regular',
                    color: charcoalGray,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
                style: TextStyle(
                  fontSize: fontSize + 2,
                  fontFamily: 'Regular',
                  color: textBlack,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _orderController,
                decoration: InputDecoration(
                  labelText: 'Order Details',
                  labelStyle: TextStyle(
                    fontSize: fontSize + 2,
                    fontFamily: 'Regular',
                    color: charcoalGray,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
                style: TextStyle(
                  fontSize: fontSize + 2,
                  fontFamily: 'Regular',
                  color: textBlack,
                ),
              ),
              const SizedBox(height: 12),
              TextWidget(
                text: 'Date: ${reservation['date']}',
                fontSize: fontSize + 2,
                color: textBlack,
                fontFamily: 'Regular',
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'Time: ${reservation['time']}',
                fontSize: fontSize + 2,
                color: textBlack,
                fontFamily: 'Regular',
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'Guests: $_numberOfGuests',
                fontSize: fontSize + 2,
                color: textBlack,
                fontFamily: 'Regular',
              ),
            ],
          ),
        ),
        actions: [
          ButtonWidget(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
            color: ashGray,
            textColor: textBlack,
            fontSize: fontSize + 1,
            height: 45,
            width: 100,
            radius: 10,
          ),
          ButtonWidget(
            label: 'Save',
            onPressed: () async {
              if (_nameController.text.isEmpty ||
                  _orderController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Please fill in all fields',
                      fontSize: fontSize,
                      color: plainWhite,
                      fontFamily: 'Regular',
                    ),
                    backgroundColor: festiveRed,
                  ),
                );
                return;
              }
              try {
                await _firestore
                    .collection('reservations')
                    .doc(table['docId'])
                    .update({
                  'name': _nameController.text,
                  'order': _orderController.text,
                  'guests': _numberOfGuests,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.of(context).pop();
                setState(() {
                  _nameController.clear();
                  _orderController.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Reservation updated successfully',
                      fontSize: fontSize,
                      color: plainWhite,
                      fontFamily: 'Regular',
                    ),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Error updating reservation: $e',
                      fontSize: fontSize,
                      color: plainWhite,
                      fontFamily: 'Regular',
                    ),
                    backgroundColor: festiveRed,
                  ),
                );
              }
            },
            color: AppTheme.primaryColor,
            textColor: plainWhite,
            fontSize: fontSize + 1,
            height: 45,
            width: 100,
            radius: 10,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.02;
    final padding = screenWidth * 0.02;

    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: plainWhite,
        elevation: 4,
        title: TextWidget(
          text: _isTableManagementMode ? 'Table Management' : 'Reservations',
          fontSize: 24,
          fontFamily: 'Bold',
          color: plainWhite,
          isBold: true,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                ButtonWidget(
                  label: 'Reservations',
                  onPressed: () {
                    setState(() {
                      _isTableManagementMode = false;
                    });
                  },
                  color: !_isTableManagementMode
                      ? plainWhite
                      : AppTheme.primaryColor.withOpacity(0.7),
                  textColor: !_isTableManagementMode
                      ? AppTheme.primaryColor
                      : plainWhite,
                  fontSize: 14,
                  height: 40,
                  radius: 8,
                  width: 120,
                ),
                const SizedBox(width: 8),
                ButtonWidget(
                  label: 'Seat Management',
                  onPressed: () {
                    setState(() {
                      _isTableManagementMode = true;
                    });
                    _loadTableReservations();
                  },
                  color: _isTableManagementMode
                      ? plainWhite
                      : AppTheme.primaryColor.withOpacity(0.7),
                  textColor: _isTableManagementMode
                      ? AppTheme.primaryColor
                      : plainWhite,
                  fontSize: 14,
                  height: 40,
                  radius: 8,
                  width: 120,
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isTableManagementMode
          ? _buildTableManagementView(context, screenWidth, fontSize, padding)
          : _buildReservationView(context, screenWidth, fontSize, padding),
    );
  }

  // Build table management view
  Widget _buildTableManagementView(BuildContext context, double screenWidth,
      double fontSize, double padding) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total tables summary
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: plainWhite,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.table_restaurant,
                    color: AppTheme.primaryColor,
                    size: fontSize * 2,
                  ),
                  const SizedBox(width: 16),
                  TextWidget(
                    text: 'Total Tables: ${_tables.length}',
                    fontSize: fontSize + 4,
                    color: textBlack,
                    isBold: true,
                    fontFamily: 'Bold',
                  ),
                  const Spacer(),
                  _buildStatusSummary(fontSize),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tables grid
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth > 1200
                    ? 4
                    : screenWidth > 800
                        ? 3
                        : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _tables.length,
              itemBuilder: (context, index) {
                final table = _tables[index];
                final status = _getTableStatus(table['id']);
                final isEnabled = _tableEnabledStatus[table['id']] ?? true;
                final reservation = _tableReservations[table['id']];

                Color statusColor;
                IconData statusIcon;

                switch (status) {
                  case 'Available':
                    statusColor = palmGreen;
                    statusIcon = Icons.check_circle;
                    break;
                  case 'Reserved':
                    statusColor = AppTheme.primaryColor;
                    statusIcon = Icons.event;
                    break;
                  case 'Disabled':
                    statusColor = festiveRed;
                    statusIcon = Icons.block;
                    break;
                  default:
                    statusColor = ashGray;
                    statusIcon = Icons.help;
                }

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: isEnabled ? plainWhite : ashGray.withOpacity(0.3),
                      border: Border.all(
                        color: statusColor,
                        width: 2,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextWidget(
                                text: table['name'],
                                fontSize: fontSize + 2,
                                color: isEnabled ? textBlack : charcoalGray,
                                isBold: true,
                                fontFamily: 'Bold',
                              ),
                              Icon(
                                statusIcon,
                                color: statusColor,
                                size: fontSize * 1.5,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextWidget(
                            text: 'Capacity: ${table['capacity']} guests',
                            fontSize: fontSize,
                            color: isEnabled
                                ? charcoalGray
                                : charcoalGray.withOpacity(0.6),
                            fontFamily: 'Regular',
                          ),
                          const SizedBox(height: 8),
                          TextWidget(
                            text: 'Status: $status',
                            fontSize: fontSize,
                            color: statusColor,
                            isBold: true,
                            fontFamily: 'Bold',
                          ),
                          if (reservation != null) ...[
                            const SizedBox(height: 8),
                            TextWidget(
                              text: 'Customer: ${reservation['userEmail']}',
                              fontSize: fontSize - 2,
                              color: textBlack,
                              fontFamily: 'Regular',
                            ),
                            TextWidget(
                              text: 'Time: ${reservation['time']}',
                              fontSize: fontSize - 2,
                              color: textBlack,
                              fontFamily: 'Regular',
                            ),
                          ],
                          SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ButtonWidget(
                                label: isEnabled ? 'Disable' : 'Enable',
                                onPressed: () =>
                                    _toggleTableStatus(table['id']),
                                color: isEnabled ? festiveRed : palmGreen,
                                textColor: plainWhite,
                                fontSize: fontSize - 2,
                                height: 35,
                                radius: 8,
                                width: 80,
                              ),
                              if (reservation != null)
                                ButtonWidget(
                                  label: 'View',
                                  onPressed: () =>
                                      _showReservationDetails(context, {
                                    ...table,
                                    'reservation': reservation,
                                    'docId': reservation['docId'],
                                  }),
                                  color: AppTheme.primaryColor,
                                  textColor: plainWhite,
                                  fontSize: fontSize - 2,
                                  height: 35,
                                  radius: 8,
                                  width: 60,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build status summary widget
  Widget _buildStatusSummary(double fontSize) {
    int availableCount = 0;
    int reservedCount = 0;
    int disabledCount = 0;

    for (var table in _tables) {
      final status = _getTableStatus(table['id']);
      switch (status) {
        case 'Available':
          availableCount++;
          break;
        case 'Reserved':
          reservedCount++;
          break;
        case 'Disabled':
          disabledCount++;
          break;
      }
    }

    return Row(
      children: [
        _buildStatusChip('Available', availableCount, palmGreen, fontSize),
        const SizedBox(width: 8),
        _buildStatusChip(
            'Reserved', reservedCount, AppTheme.primaryColor, fontSize),
        const SizedBox(width: 8),
        _buildStatusChip('Disabled', disabledCount, festiveRed, fontSize),
      ],
    );
  }

  // Build status chip widget
  Widget _buildStatusChip(
      String label, int count, Color color, double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          TextWidget(
            text: '$label: ',
            fontSize: fontSize,
            color: color,
            fontFamily: 'Regular',
          ),
          TextWidget(
            text: '$count',
            fontSize: fontSize,
            color: color,
            isBold: true,
            fontFamily: 'Bold',
          ),
        ],
      ),
    );
  }

  // Build reservation view (original view)
  Widget _buildReservationView(BuildContext context, double screenWidth,
      double fontSize, double padding) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'Select Date',
                    fontSize: 24,
                    color: textBlack,
                    isBold: true,
                    fontFamily: 'Bold',
                    letterSpacing: 1,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: plainWhite,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWidget(
                            text:
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                            fontSize: fontSize + 2,
                            color: textBlack,
                            isBold: true,
                            fontFamily: 'Bold',
                          ),
                          ButtonWidget(
                            label: 'Pick Date',
                            onPressed: () => _selectDate(context),
                            color: AppTheme.primaryColor,
                            textColor: plainWhite,
                            fontSize: fontSize + 1,
                            height: 50,
                            radius: 12,
                            width: 120,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextWidget(
                    text: 'Number of Guests',
                    fontSize: 24,
                    color: textBlack,
                    isBold: true,
                    fontFamily: 'Bold',
                    letterSpacing: 1,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ButtonWidget(
                        label: '-',
                        onPressed: () {
                          setState(() {
                            if (_numberOfGuests > 1) _numberOfGuests--;
                          });
                        },
                        color: ashGray,
                        textColor: textBlack,
                        fontSize: fontSize + 1,
                        height: 50,
                        width: 60,
                        radius: 10,
                      ),
                      const SizedBox(width: 16),
                      TextWidget(
                        text:
                            '$_numberOfGuests Guest${_numberOfGuests > 1 ? 's' : ''}',
                        fontSize: fontSize + 2,
                        color: textBlack,
                        fontFamily: 'Regular',
                      ),
                      const SizedBox(width: 16),
                      ButtonWidget(
                        label: '+',
                        onPressed: () {
                          setState(() {
                            _numberOfGuests++;
                          });
                        },
                        color: AppTheme.primaryColor,
                        textColor: plainWhite,
                        fontSize: fontSize + 1,
                        height: 50,
                        width: 60,
                        radius: 10,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextWidget(
                    text: 'Select Time',
                    fontSize: 24,
                    color: textBlack,
                    isBold: true,
                    fontFamily: 'Bold',
                    letterSpacing: 1,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _availableTimeSlots.map((time) {
                      final isSelected = _selectedTime == time;
                      return ChoiceChip(
                        showCheckmark: false,
                        label: TextWidget(
                          text: time,
                          fontSize: fontSize + 1,
                          color: isSelected ? plainWhite : textBlack,
                          isBold: isSelected,
                          fontFamily: 'Regular',
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedTime = time;
                              _selectedTableId = null;
                            });
                            _updateTableAvailability();
                          }
                        },
                        backgroundColor: cloudWhite,
                        selectedColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : ashGray,
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        elevation: isSelected ? 4 : 0,
                        pressElevation: 6,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: 'Select Table',
                  fontSize: 24,
                  color: textBlack,
                  isBold: true,
                  fontFamily: 'Bold',
                  letterSpacing: 1,
                ),
                const SizedBox(height: 12),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio:
                              screenWidth * 0.25 / (screenWidth * 0.25),
                        ),
                        itemCount: _tables.length,
                        itemBuilder: (context, index) {
                          final table = _tables[index];
                          final isSelected = _selectedTableId == table['id'];
                          final isAvailable =
                              (_tableAvailability[table['id']] ?? true) &&
                                  (_tableEnabledStatus[table['id']] ?? true) &&
                                  _numberOfGuests <= table['capacity'];
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: InkWell(
                              onTap: () {
                                if (isAvailable && _selectedTime != null) {
                                  setState(() {
                                    _selectedTableId = table['id'];
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                padding: EdgeInsets.all(padding),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: isAvailable
                                      ? plainWhite
                                      : ashGray.withOpacity(0.3),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : isAvailable
                                            ? palmGreen
                                            : festiveRed,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text: table['name'],
                                      fontSize: fontSize + 2,
                                      color: isAvailable
                                          ? textBlack
                                          : charcoalGray,
                                      isBold: true,
                                      fontFamily: 'Bold',
                                    ),
                                    const SizedBox(height: 8),
                                    TextWidget(
                                      text:
                                          'Capacity: ${table['capacity']} guests',
                                      fontSize: fontSize,
                                      color: isAvailable
                                          ? charcoalGray
                                          : charcoalGray.withOpacity(0.6),
                                      fontFamily: 'Regular',
                                    ),
                                    const SizedBox(height: 8),
                                    TextWidget(
                                      text: isAvailable
                                          ? 'Available'
                                          : 'Occupied',
                                      fontSize: fontSize,
                                      color: isAvailable
                                          ? AppTheme.primaryColor
                                          : charcoalGray,
                                      isBold: true,
                                      fontFamily: 'Bold',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 20),
                Center(
                  child: ButtonWidget(
                    label: 'Create Reservation',
                    onPressed: _selectedTime != null && _selectedTableId != null
                        ? () => _showCreateReservationDialog(context)
                        : () {},
                    color: _selectedTime != null && _selectedTableId != null
                        ? AppTheme.primaryColor
                        : ashGray,
                    textColor: plainWhite,
                    fontSize: fontSize + 2,
                    height: 60,
                    radius: 10,
                    width: screenWidth * 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
