import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
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
  Map<String, String> _tableDisableReasons = {};
  Timer? _reservationExpiryTimer;
  StreamSubscription? _reservationsListener;

  // Tab management
  int _selectedTabIndex = 0; // 0: Monitoring, 1: History, 2: Tables

  // Monitoring state
  List<Map<String, dynamic>> _activeReservations = [];
  Timer? _countdownTimer;
  Map<String, Duration> _reservationCountdowns = {};

  // History state
  List<Map<String, dynamic>> _reservationHistory = [];
  String _historyFilter = 'all'; // all, completed, cancelled
  DateTime? _historyStartDate;
  DateTime? _historyEndDate;

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
      _tableDisableReasons[table['id']] = '';
    }

    // Generate available time slots based on operating hours
    _generateTimeSlots();

    // Start reservation expiry monitoring
    _startReservationExpiryMonitoring();

    // Set up real-time listener for reservations
    _setupRealtimeListener();

    // Load active reservations for monitoring
    _loadActiveReservations();

    // Start countdown timer
    _startCountdownTimer();

    // Load reservation history
    _loadReservationHistory();

    // Load table disable reasons
    _loadTableDisableReasons();

    setState(() {
      _isLoading = false;
    });
  }

  // Set up real-time listener for reservations
  void _setupRealtimeListener() {
    final today = DateFormat('yyyy-MM-dd').format(_selectedDate);

    _reservationsListener?.cancel();
    _reservationsListener = _firestore
        .collection('reservations')
        .where('branch', isEqualTo: _currentBranch)
        .where('date', isEqualTo: today)
        .where('status', whereIn: ['pending', 'confirmed', 'checked_in'])
        .snapshots()
        .listen((snapshot) {
          Map<String, dynamic> reservations = {};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final tableId = data['tableId'] as String;

            // Only show one reservation per table (most recent)
            if (!reservations.containsKey(tableId)) {
              reservations[tableId] = {
                ...data,
                'docId': doc.id,
                'time': data['timeSlot'] ?? data['time'],
                'date': data['dateDisplay'] ?? data['date'],
              };
            }
          }

          if (mounted) {
            setState(() {
              _tableReservations = reservations;
            });

            // Check for any reservations that might have ended
            _checkAndUpdateEndedReservations(reservations);
          }
        });
  }

  // Start monitoring for reservation expiry
  void _startReservationExpiryMonitoring() {
    _reservationExpiryTimer?.cancel();
    _reservationExpiryTimer =
        Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkReservationExpiry();
    });
  }

  // Check for expired reservations and update table status
  Future<void> _checkReservationExpiry() async {
    try {
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);

      // Get all active reservations for today
      final QuerySnapshot snapshot = await _firestore
          .collection('reservations')
          .where('branch', isEqualTo: _currentBranch)
          .where('date', isEqualTo: today)
          .where('status', whereIn: ['confirmed', 'checked_in']).get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Parse reservation date and time
        final String dateStr = data['date'] ?? '';
        final String timeStr = data['timeSlot'] ?? data['time'] ?? '';

        if (dateStr.isEmpty || timeStr.isEmpty) continue;

        // Parse date (yyyy-MM-dd format)
        final List<String> dateParts = dateStr.split('-');
        final DateTime reservationDate = DateTime(
          int.parse(dateParts[0]), // year
          int.parse(dateParts[1]), // month
          int.parse(dateParts[2]), // day
        );

        // Parse time (format: "7:00 AM" or "7:00 PM")
        final List<String> timeParts = timeStr.split(' ');
        final List<String> hourMinute = timeParts[0].split(':');
        int hour = int.parse(hourMinute[0]);
        final int minute = int.parse(hourMinute[1]);

        // Convert to 24-hour format
        if (timeParts.length > 1) {
          if (timeParts[1] == 'PM' && hour != 12) {
            hour += 12;
          } else if (timeParts[1] == 'AM' && hour == 12) {
            hour = 0;
          }
        }

        final DateTime reservationDateTime = DateTime(
          reservationDate.year,
          reservationDate.month,
          reservationDate.day,
          hour,
          minute,
        );

        // Calculate end time (reservation time + 55 minutes)
        final DateTime endTime =
            reservationDateTime.add(const Duration(minutes: 55));

        // Check if reservation time has ended
        if (now.isAfter(endTime)) {
          // Update reservation status to completed
          await _firestore.collection('reservations').doc(doc.id).update({
            'status': 'completed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Refresh table reservations after updating statuses
      await _loadTableReservations();
      await _loadActiveReservations();
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
      final String status = reservation['status'] ?? '';

      // Only consider table reserved if status is confirmed or checked_in
      // and the reservation time hasn't ended
      if (status == 'confirmed' || status == 'checked_in') {
        // Check if reservation time has ended
        if (!_isReservationTimeEnded(reservation)) {
          return 'Reserved';
        }
      }
    }

    return 'Available';
  }

  // Toggle table enabled/disabled status with reason
  Future<void> _toggleTableStatus(
      String tableId, bool newStatus, String reason) async {
    try {
      // Update local state
      setState(() {
        _tableEnabledStatus[tableId] = newStatus;
        _tableDisableReasons[tableId] = newStatus ? '' : reason;
      });

      // Update in Firestore
      await _firestore.collection('tables').doc(tableId).set({
        'enabled': newStatus,
        'disableReason': newStatus ? '' : reason,
        'branch': _currentBranch,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final tableName = _tables.firstWhere((t) => t['id'] == tableId)['name'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text:
                'Table $tableName ${newStatus ? 'enabled' : 'disabled'}${!newStatus ? ': $reason' : ''}',
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

  // Load table disable reasons from Firestore
  Future<void> _loadTableDisableReasons() async {
    try {
      for (var table in _tables) {
        final docSnapshot =
            await _firestore.collection('tables').doc(table['id']).get();
        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          setState(() {
            _tableEnabledStatus[table['id']] = data['enabled'] ?? true;
            _tableDisableReasons[table['id']] = data['disableReason'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading table disable reasons: $e');
    }
  }

  // Show dialog to input disable reason
  Future<void> _showDisableReasonDialog(
      String tableId, String tableName) async {
    final TextEditingController reasonController = TextEditingController();
    bool isDisabling = _tableEnabledStatus[tableId] ?? true;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: plainWhite,
        title: TextWidget(
          text: isDisabling ? 'Disable Table' : 'Enable Table',
          fontSize: 20,
          color: textBlack,
          isBold: true,
          fontFamily: 'Bold',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: isDisabling
                  ? 'Please provide a reason for disabling $tableName:'
                  : 'Are you sure you want to enable $tableName?',
              fontSize: 16,
              color: textBlack,
              fontFamily: 'Regular',
            ),
            if (isDisabling) ...[
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ashGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ButtonWidget(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
            color: ashGray,
            textColor: textBlack,
            fontSize: 14,
            height: 40,
            width: 100,
            radius: 10,
          ),
          ButtonWidget(
            label: isDisabling ? 'Disable' : 'Enable',
            onPressed: () async {
              Navigator.of(context).pop();
              if (isDisabling && reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Please provide a reason for disabling the table',
                      fontSize: 14,
                      color: plainWhite,
                      fontFamily: 'Regular',
                    ),
                    backgroundColor: festiveRed,
                  ),
                );
                return;
              }
              await _toggleTableStatus(tableId, isDisabling ? false : true,
                  reasonController.text.trim());
            },
            color: isDisabling ? festiveRed : palmGreen,
            textColor: plainWhite,
            fontSize: 14,
            height: 40,
            width: 100,
            radius: 10,
          ),
        ],
      ),
    );
  }

  // Load table reservations for today
  Future<void> _loadTableReservations() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final QuerySnapshot snapshot = await _firestore
          .collection('reservations')
          .where('branch', isEqualTo: _currentBranch)
          .where('date', isEqualTo: today)
          .where('status',
              whereIn: ['pending', 'confirmed', 'checked_in']).get();

      Map<String, dynamic> reservations = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final tableId = data['tableId'] as String;

        // Only show one reservation per table (most recent)
        if (!reservations.containsKey(tableId)) {
          reservations[tableId] = {
            ...data,
            'docId': doc.id,
            'time': data['timeSlot'] ?? data['time'], // Support both formats
            'date': data['dateDisplay'] ?? data['date'],
          };
        }
      }

      setState(() {
        _tableReservations = reservations;
      });
    } catch (e) {
      print('Error loading table reservations: $e');
    }
  }

  // Tables configuration (3 tables with 2 seats, 2 tables with 4 seats)
  final List<Map<String, dynamic>> _tables =
      BranchService.getSelectedBranch() == 'Kaffi Cafe - Eloisa St'
          ? [
              {'id': 'table1', 'name': 'Table 1', 'capacity': 2},
              {'id': 'table2', 'name': 'Table 2', 'capacity': 2},
              {'id': 'table3', 'name': 'Table 3', 'capacity': 2},
              {'id': 'table4', 'name': 'Table 4', 'capacity': 4},
              {'id': 'table5', 'name': 'Table 5', 'capacity': 4},
            ]
          : [
              {'id': 'table11', 'name': 'Table 1', 'capacity': 2},
              {'id': 'table22', 'name': 'Table 2', 'capacity': 2},
              {'id': 'table33', 'name': 'Table 3', 'capacity': 2},
              {'id': 'table44', 'name': 'Table 4', 'capacity': 4},
              {'id': 'table55', 'name': 'Table 5', 'capacity': 4},
            ];

  // Generate available time slots based on operating hours (10:00 AM - 2:00 AM)
  // Format: 10:00 AM - 10:55 AM (55 mins reservation, 5 mins cleaning)
  void _generateTimeSlots() {
    final now = DateTime.now();
    final List<String> slots = [];

    // Operating hours: 10:00 AM to 2:00 AM (next day)
    // 10 AM to 11 PM (10-23), then 12 AM to 1 AM (0-1)
    List<int> hours = [];

    // Add 10 AM to 11 PM (10-23)
    for (int hour = 10; hour <= 23; hour++) {
      hours.add(hour);
    }

    // Add 12 AM to 1 AM (0-1) for next day
    hours.add(0);
    hours.add(1);

    for (int hour in hours) {
      // Skip past hours for today
      if (_selectedDate.day == now.day &&
          _selectedDate.month == now.month &&
          _selectedDate.year == now.year &&
          hour < now.hour) {
        continue;
      }

      // Format hour for 12-hour clock
      String period = hour < 12 ? 'AM' : 'PM';
      int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      String startTime = '$displayHour:00 $period';
      slots.add(startTime); // Store just start time for compatibility
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
      // Check both 'time' and 'timeSlot' fields for compatibility
      final QuerySnapshot snapshot = await _firestore
          .collection('reservations')
          .where('branch', isEqualTo: _currentBranch)
          .where('tableId', isEqualTo: tableId)
          .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(date))
          .where('status',
              whereIn: ['pending', 'confirmed', 'checked_in']).get();

      // Filter by time slot (check both old 'time' and new 'timeSlot' fields)
      final hasConflict = snapshot.docs.any((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final reservedTime = data['timeSlot'] ?? data['time'];
        return reservedTime == time;
      });

      return !hasConflict;
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

  // Load active reservations for monitoring
  Future<void> _loadActiveReservations() async {
    try {
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);

      final snapshot = await _firestore
          .collection('reservations')
          .where('branch', isEqualTo: _currentBranch)
          .where('date', isEqualTo: today)
          .where('status', whereIn: ['confirmed', 'checked_in']).get();

      List<Map<String, dynamic>> active = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        active.add({
          'id': doc.id,
          ...data,
        });
      }

      // Sort by time
      active.sort((a, b) {
        final timeA = a['timeSlot'] ?? a['time'] ?? '';
        final timeB = b['timeSlot'] ?? b['time'] ?? '';
        return timeA.compareTo(timeB);
      });

      if (mounted) {
        setState(() {
          _activeReservations = active;
        });
      }
    } catch (e) {
      print('Error loading active reservations: \$e');
    }
  }

  // Start countdown timer for active reservations
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdowns();
      _checkPreOrderAlerts();
    });
  }

  // Update countdown timers
  void _updateCountdowns() {
    final now = DateTime.now();
    Map<String, Duration> newCountdowns = {};

    for (var reservation in _activeReservations) {
      try {
        // Parse reservation time
        final dateStr = reservation['date'];
        final timeStr = reservation['timeSlot'] ?? reservation['time'];

        if (dateStr == null || timeStr == null) continue;

        // Parse date (yyyy-MM-dd)
        final dateParts = dateStr.split('-');
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);

        // Parse time (e.g., "7:00 AM")
        final timeParts = timeStr.split(' ');
        final hourMin = timeParts[0].split(':');
        int hour = int.parse(hourMin[0]);
        final minute = int.parse(hourMin[1]);

        // Convert to 24-hour format
        if (timeParts.length > 1) {
          if (timeParts[1] == 'PM' && hour != 12) {
            hour += 12;
          } else if (timeParts[1] == 'AM' && hour == 12) {
            hour = 0;
          }
        }

        final reservationTime = DateTime(year, month, day, hour, minute);
        final endTime = reservationTime.add(const Duration(minutes: 55));

        // Calculate remaining time
        if (now.isAfter(reservationTime) && now.isBefore(endTime)) {
          // Reservation is active - countdown to end
          final remaining = endTime.difference(now);
          newCountdowns[reservation['id']] = remaining;
        } else if (now.isBefore(reservationTime)) {
          // Reservation hasn't started - show time until start
          final remaining = reservationTime.difference(now);
          newCountdowns[reservation['id']] = remaining;
        }
      } catch (e) {
        print('Error calculating countdown: \$e');
      }
    }

    if (mounted) {
      setState(() {
        _reservationCountdowns = newCountdowns;
      });
    }
  }

  // Check for pre-order alerts (10 minutes before reservation)
  void _checkPreOrderAlerts() {
    final now = DateTime.now();

    for (var reservation in _activeReservations) {
      try {
        final dateStr = reservation['date'];
        final timeStr = reservation['timeSlot'] ?? reservation['time'];

        if (dateStr == null || timeStr == null) continue;

        // Parse date and time
        final dateParts = dateStr.split('-');
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);

        final timeParts = timeStr.split(' ');
        final hourMin = timeParts[0].split(':');
        int hour = int.parse(hourMin[0]);
        final minute = int.parse(hourMin[1]);

        if (timeParts.length > 1) {
          if (timeParts[1] == 'PM' && hour != 12) {
            hour += 12;
          } else if (timeParts[1] == 'AM' && hour == 12) {
            hour = 0;
          }
        }

        final reservationTime = DateTime(year, month, day, hour, minute);
        final alertTime = reservationTime.subtract(const Duration(minutes: 10));

        // Check if we're within the alert window (10 minutes before)
        if (now.isAfter(alertTime) &&
            now.isBefore(reservationTime) &&
            reservation['alertShown'] != true) {
          // Show alert
          _showPreOrderAlert(reservation);
          // Mark as shown
          reservation['alertShown'] = true;
        }
      } catch (e) {
        print('Error checking pre-order alert: \$e');
      }
    }
  }

  // Show pre-order alert
  void _showPreOrderAlert(Map<String, dynamic> reservation) {
    if (!mounted) return;

    final tableName = reservation['tableName'] ?? 'Unknown';
    final userName =
        reservation['userName'] ?? reservation['userEmail'] ?? 'Customer';
    final timeDisplay =
        reservation['timeSlotDisplay'] ?? reservation['time'] ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.notifications_active, color: plainWhite, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextWidget(
                    text: 'Pre-Order Alert!',
                    fontSize: 16,
                    color: plainWhite,
                    isBold: true,
                    fontFamily: 'Bold',
                  ),
                  const SizedBox(height: 4),
                  TextWidget(
                    text:
                        '$userName for $tableName will arrive at $timeDisplay — prepare order now.',
                    fontSize: 14,
                    color: plainWhite,
                    fontFamily: 'Regular',
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Load reservation history
  Future<void> _loadReservationHistory() async {
    try {
      Query query = _firestore
          .collection('reservations')
          .where('branch', isEqualTo: _currentBranch);

      // Apply date filters
      if (_historyStartDate != null) {
        final startStr = DateFormat('yyyy-MM-dd').format(_historyStartDate!);
        query = query.where('date', isGreaterThanOrEqualTo: startStr);
      }
      if (_historyEndDate != null) {
        final endStr = DateFormat('yyyy-MM-dd').format(_historyEndDate!);
        query = query.where('date', isLessThanOrEqualTo: endStr);
      }

      // Apply status filter
      if (_historyFilter != 'all') {
        query = query.where('status', isEqualTo: _historyFilter);
      }

      // Order by date descending
      query = query.orderBy('date', descending: true).limit(100);

      final snapshot = await query.get();

      List<Map<String, dynamic>> history = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        history.add({
          'id': doc.id,
          ...data,
        });
      }

      if (mounted) {
        setState(() {
          _reservationHistory = history;
        });
      }
    } catch (e) {
      print('Error loading reservation history: \$e');
    }
  }

  @override
  void dispose() {
    _reservationExpiryTimer?.cancel();
    _reservationsListener?.cancel();
    _countdownTimer?.cancel();
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
      // Update real-time listener for new date
      _setupRealtimeListener();
    }
  }

  void _showTableReservationDetails(BuildContext context,
      Map<String, dynamic> table, Map<String, dynamic>? reservation) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.018;

    if (reservation == null) {
      // Show available table dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: plainWhite,
          title: TextWidget(
            text: '${table['name']} - Available',
            fontSize: fontSize + 4,
            color: textBlack,
            isBold: true,
            fontFamily: 'Bold',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: 'Capacity: ${table['capacity']} guests',
                fontSize: fontSize + 2,
                color: textBlack,
                fontFamily: 'Regular',
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'Status: Available',
                fontSize: fontSize + 2,
                color: palmGreen,
                isBold: true,
                fontFamily: 'Bold',
              ),
              const SizedBox(height: 8),
              TextWidget(
                text:
                    'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                fontSize: fontSize + 2,
                color: textBlack,
                fontFamily: 'Regular',
              ),
            ],
          ),
          actions: [
            ButtonWidget(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
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
      return;
    }

    // Show reserved table dialog with detailed information
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: plainWhite,
        title: TextWidget(
          text: '${table['name']} - Reserved',
          fontSize: fontSize + 4,
          color: textBlack,
          isBold: true,
          fontFamily: 'Bold',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text:
                    'Customer: ${reservation['userName'] ?? reservation['userEmail'] ?? 'N/A'}',
                fontSize: fontSize + 2,
                color: textBlack,
                fontFamily: 'Regular',
              ),
              const SizedBox(height: 8),
              TextWidget(
                text:
                    'Date: ${reservation['dateDisplay'] ?? reservation['date']}',
                fontSize: fontSize + 2,
                color: textBlack,
                fontFamily: 'Regular',
              ),
              const SizedBox(height: 8),
              TextWidget(
                text:
                    'Time: ${reservation['timeSlotDisplay'] ?? reservation['time']}',
                fontSize: fontSize + 2,
                color: textBlack,
                fontFamily: 'Regular',
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'Guests: ${reservation['guests'] ?? 'N/A'}',
                fontSize: fontSize + 2,
                color: textBlack,
                fontFamily: 'Regular',
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'Status: ${reservation['status'] ?? 'confirmed'}',
                fontSize: fontSize + 2,
                color: reservation['status'] == 'confirmed'
                    ? AppTheme.primaryColor
                    : reservation['status'] == 'pending'
                        ? Colors.orange
                        : festiveRed,
                isBold: true,
                fontFamily: 'Bold',
              ),
              if (reservation['createdAt'] != null) ...[
                const SizedBox(height: 8),
                TextWidget(
                  text:
                      'Created: ${_formatTimestamp(reservation['createdAt'])}',
                  fontSize: fontSize + 1,
                  color: charcoalGray,
                  fontFamily: 'Regular',
                ),
              ],
              if (reservation['updatedAt'] != null) ...[
                const SizedBox(height: 8),
                TextWidget(
                  text:
                      'Updated: ${_formatTimestamp(reservation['updatedAt'])}',
                  fontSize: fontSize + 1,
                  color: charcoalGray,
                  fontFamily: 'Regular',
                ),
              ],
              if (reservation['orderDetails'] != null) ...[
                const SizedBox(height: 8),
                TextWidget(
                  text: 'Order: ${reservation['orderDetails']}',
                  fontSize: fontSize + 2,
                  color: textBlack,
                  fontFamily: 'Regular',
                ),
              ],
              if (reservation['source'] != null) ...[
                const SizedBox(height: 8),
                TextWidget(
                  text: 'Source: ${reservation['source']}',
                  fontSize: fontSize + 1,
                  color: charcoalGray,
                  fontFamily: 'Regular',
                ),
              ],
              // Check if reservation is ongoing
              if (_isReservationOngoing(reservation)) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palmGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palmGreen),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: palmGreen, size: fontSize + 2),
                      const SizedBox(width: 8),
                      TextWidget(
                        text: 'Ongoing',
                        fontSize: fontSize + 1,
                        color: palmGreen,
                        isBold: true,
                        fontFamily: 'Bold',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ButtonWidget(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
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

  // Format timestamp for display
  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
  }

  // Check if reservation is ongoing
  bool _isReservationOngoing(Map<String, dynamic> reservation) {
    try {
      final dateStr = reservation['date'];
      final timeStr = reservation['timeSlot'] ?? reservation['time'];

      if (dateStr == null || timeStr == null) return false;

      // Parse date (yyyy-MM-dd)
      final dateParts = dateStr.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // Parse time (e.g., "7:00 AM")
      final timeParts = timeStr.split(' ');
      final hourMin = timeParts[0].split(':');
      int hour = int.parse(hourMin[0]);
      final minute = int.parse(hourMin[1]);

      // Convert to 24-hour format
      if (timeParts.length > 1) {
        if (timeParts[1] == 'PM' && hour != 12) {
          hour += 12;
        } else if (timeParts[1] == 'AM' && hour == 12) {
          hour = 0;
        }
      }

      final reservationTime = DateTime(year, month, day, hour, minute);
      final endTime = reservationTime.add(const Duration(minutes: 55));
      final now = DateTime.now();

      return now.isAfter(reservationTime) && now.isBefore(endTime);
    } catch (e) {
      return false;
    }
  }

  // Check if reservation time has ended
  bool _isReservationTimeEnded(Map<String, dynamic> reservation) {
    try {
      final dateStr = reservation['date'];
      final timeStr = reservation['timeSlot'] ?? reservation['time'];

      if (dateStr == null || timeStr == null) return true;

      // Parse date (yyyy-MM-dd)
      final dateParts = dateStr.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // Parse time (e.g., "7:00 AM")
      final timeParts = timeStr.split(' ');
      final hourMin = timeParts[0].split(':');
      int hour = int.parse(hourMin[0]);
      final minute = int.parse(hourMin[1]);

      // Convert to 24-hour format
      if (timeParts.length > 1) {
        if (timeParts[1] == 'PM' && hour != 12) {
          hour += 12;
        } else if (timeParts[1] == 'AM' && hour == 12) {
          hour = 0;
        }
      }

      final reservationTime = DateTime(year, month, day, hour, minute);
      final endTime = reservationTime.add(const Duration(minutes: 55));
      final now = DateTime.now();

      return now.isAfter(endTime);
    } catch (e) {
      print('Error checking if reservation time ended: $e');
      return true; // Assume ended if there's an error
    }
  }

  // Check and update reservations that have ended
  void _checkAndUpdateEndedReservations(Map<String, dynamic> reservations) {
    final now = DateTime.now();
    bool needsUpdate = false;

    reservations.forEach((tableId, reservation) {
      if (_isReservationTimeEnded(reservation)) {
        needsUpdate = true;
      }
    });

    if (needsUpdate) {
      // Trigger a check for expired reservations
      _checkReservationExpiry();
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
                      text:
                          'Customer: ${reservation['userName'] ?? reservation['userEmail']}',
                      fontSize: fontSize + 2,
                      color: textBlack,
                      fontFamily: 'Regular',
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text:
                          'Date: ${reservation['dateDisplay'] ?? reservation['date']}',
                      fontSize: fontSize + 2,
                      color: textBlack,
                      fontFamily: 'Regular',
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text:
                          'Time: ${reservation['timeSlotDisplay'] ?? reservation['time']}',
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
                    if (reservation['orderDetails'] != null) ...[
                      const SizedBox(height: 8),
                      TextWidget(
                        text: 'Order: ${reservation['orderDetails']}',
                        fontSize: fontSize + 2,
                        color: textBlack,
                        fontFamily: 'Regular',
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextWidget(
                      text: 'Status: ${reservation['status']}',
                      fontSize: fontSize + 2,
                      color: reservation['status'] == 'confirmed'
                          ? AppTheme.primaryColor
                          : reservation['status'] == 'pending'
                              ? Colors.orange
                              : festiveRed,
                      fontFamily: 'Regular',
                    ),
                    if (reservation['source'] != null) ...[
                      const SizedBox(height: 8),
                      TextWidget(
                        text: 'Source: ${reservation['source']}',
                        fontSize: fontSize + 2,
                        color: charcoalGray,
                        fontFamily: 'Regular',
                      ),
                    ],
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.02;
    final padding = screenWidth * 0.02;

    return Scaffold(
      drawer: const DrawerWidget(),
      backgroundColor: cloudWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: plainWhite,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: TextWidget(
            key: ValueKey(_selectedTabIndex),
            text: _selectedTabIndex == 0
                ? 'Monitoring'
                : _selectedTabIndex == 1
                    ? 'History'
                    : 'Tables',
            fontSize: 24,
            fontFamily: 'Bold',
            color: plainWhite,
            isBold: true,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                _buildTabButton(
                  'Monitoring',
                  0,
                  110,
                  () {
                    setState(() {
                      _selectedTabIndex = 0;
                      _isTableManagementMode = false;
                    });
                    _loadActiveReservations();
                  },
                ),
                const SizedBox(width: 6),
                _buildTabButton(
                  'History',
                  1,
                  80,
                  () {
                    setState(() {
                      _selectedTabIndex = 1;
                      _isTableManagementMode = false;
                    });
                    _loadReservationHistory();
                  },
                ),
                const SizedBox(width: 6),
                _buildTabButton(
                  'Tables',
                  2,
                  80,
                  () {
                    setState(() {
                      _selectedTabIndex = 2;
                      _isTableManagementMode = true;
                    });
                    _loadTableReservations();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedTabIndex == 0
            ? _buildMonitoringView(context, screenWidth, fontSize, padding)
            : _selectedTabIndex == 1
                ? _buildHistoryView(context, screenWidth, fontSize, padding)
                : _buildTableManagementView(
                    context, screenWidth, fontSize, padding),
      ),
    );
  }

  // Build animated tab button
  Widget _buildTabButton(
      String label, int index, double width, VoidCallback onPressed) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  _selectedTabIndex == index ? plainWhite : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: plainWhite.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextWidget(
              text: label,
              fontSize: 13,
              fontFamily: 'Medium',
              color: _selectedTabIndex == index
                  ? AppTheme.primaryColor
                  : plainWhite,
              isBold: _selectedTabIndex == index,
            ),
          ),
        ),
      ),
    );
  }

  // Build table management view
  Widget _buildTableManagementView(BuildContext context, double screenWidth,
      double fontSize, double padding) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cloudWhite,
            plainWhite,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total tables summary with modern design
            Container(
              padding: const EdgeInsets.all(15.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: plainWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.table_restaurant,
                      color: plainWhite,
                      size: fontSize * 2,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: 'Table Management',
                          fontSize: fontSize + 1,
                          color: ashGray,
                          fontFamily: 'Regular',
                        ),
                        TextWidget(
                          text: '${_tables.length} Total Tables',
                          fontSize: fontSize + 4,
                          color: textBlack,
                          isBold: true,
                          fontFamily: 'Bold',
                        ),
                        TextWidget(
                          text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                          fontSize: fontSize + 4,
                          color: textBlack,
                          isBold: true,
                          fontFamily: 'Bold',
                        ),
                      ],
                    ),
                  ),
                  _buildModernStatusSummary(fontSize),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Table management hint
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                    size: fontSize * 1.2,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextWidget(
                      text:
                          'Long press on any table to enable/disable it. Disabled tables will show a reason and cannot be reserved.',
                      fontSize: fontSize - 1,
                      color: AppTheme.primaryColor,
                      fontFamily: 'Medium',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tables grid with modern cards
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenWidth > 1200
                      ? 4
                      : screenWidth > 800
                          ? 3
                          : 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
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
                  Color statusGradientStart;
                  Color statusGradientEnd;
                  Color cardColor;

                  switch (status) {
                    case 'Available':
                      statusColor = palmGreen;
                      statusIcon = Icons.check_circle;
                      statusGradientStart = palmGreen;
                      statusGradientEnd = palmGreen.withOpacity(0.7);
                      cardColor = palmGreen.withOpacity(0.1);
                      break;
                    case 'Reserved':
                      statusColor = AppTheme.primaryColor;
                      statusIcon = Icons.event;
                      statusGradientStart = AppTheme.primaryColor;
                      statusGradientEnd =
                          AppTheme.primaryColor.withOpacity(0.7);
                      cardColor = AppTheme.primaryColor.withOpacity(0.1);
                      break;
                    case 'Disabled':
                      statusColor = festiveRed;
                      statusIcon = Icons.block;
                      statusGradientStart = festiveRed;
                      statusGradientEnd = festiveRed.withOpacity(0.7);
                      cardColor = festiveRed.withOpacity(0.1);
                      break;
                    default:
                      statusColor = ashGray;
                      statusIcon = Icons.help;
                      statusGradientStart = ashGray;
                      statusGradientEnd = ashGray.withOpacity(0.7);
                      cardColor = ashGray.withOpacity(0.1);
                  }

                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    child: Transform.translate(
                      offset: Offset(0, index % 2 == 0 ? 0 : 5),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color:
                              isEnabled ? plainWhite : ashGray.withOpacity(0.3),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showTableReservationDetails(
                                context, table, reservation),
                            onLongPress: () => _showDisableReasonDialog(
                                table['id'], table['name']),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Table icon with gradient background
                                    Center(
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              statusGradientStart,
                                              statusGradientEnd,
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  statusColor.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.table_restaurant,
                                          color: plainWhite,
                                          size: fontSize * 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Table name
                                    Center(
                                      child: TextWidget(
                                        text: table['name'],
                                        fontSize: fontSize + 2,
                                        color: isEnabled
                                            ? textBlack
                                            : charcoalGray,
                                        isBold: true,
                                        fontFamily: 'Bold',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Capacity info
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.people,
                                              size: fontSize - 2,
                                              color: statusColor,
                                            ),
                                            const SizedBox(width: 6),
                                            TextWidget(
                                              text:
                                                  '${table['capacity']} guests',
                                              fontSize: fontSize - 1,
                                              color: statusColor,
                                              fontFamily: 'Medium',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Status badge with gradient
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              statusGradientStart,
                                              statusGradientEnd,
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  statusColor.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              statusIcon,
                                              color: plainWhite,
                                              size: fontSize,
                                            ),
                                            const SizedBox(width: 6),
                                            TextWidget(
                                              text: status,
                                              fontSize: fontSize,
                                              color: plainWhite,
                                              isBold: true,
                                              fontFamily: 'Bold',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Show disable reason if table is disabled
                                    if (!isEnabled &&
                                        _tableDisableReasons[table['id']]
                                                ?.isNotEmpty ==
                                            true) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: festiveRed.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color:
                                                  festiveRed.withOpacity(0.3)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.info,
                                                  size: fontSize - 2,
                                                  color: festiveRed,
                                                ),
                                                const SizedBox(width: 4),
                                                TextWidget(
                                                  text: 'Disabled',
                                                  fontSize: fontSize - 2,
                                                  color: festiveRed,
                                                  isBold: true,
                                                  fontFamily: 'Bold',
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            TextWidget(
                                              text: _tableDisableReasons[
                                                      table['id']] ??
                                                  '',
                                              fontSize: fontSize - 2,
                                              color: festiveRed,
                                              fontFamily: 'Regular',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (reservation != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: fontSize - 2,
                                                  color: AppTheme.primaryColor,
                                                ),
                                                const SizedBox(width: 6),
                                                TextWidget(
                                                  text: reservation[
                                                          'timeSlotDisplay'] ??
                                                      reservation['time'] ??
                                                      'N/A',
                                                  fontSize: fontSize - 1,
                                                  color: AppTheme.primaryColor,
                                                  fontFamily: 'Medium',
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: fontSize - 2,
                                                  color: AppTheme.primaryColor,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: TextWidget(
                                                    text: reservation[
                                                            'userName'] ??
                                                        reservation[
                                                            'userEmail'] ??
                                                        'N/A',
                                                    fontSize: fontSize - 2,
                                                    color: textBlack,
                                                    fontFamily: 'Regular',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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

  // Build monitoring view
  Widget _buildMonitoringView(BuildContext context, double screenWidth,
      double fontSize, double padding) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cloudWhite,
            plainWhite,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with animated gradient card
            Hero(
              tag: 'monitoring_header',
              child: Container(
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.9),
                      AppTheme.primaryColor.withOpacity(0.7),
                      AppTheme.primaryColor.withOpacity(0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: plainWhite.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.monitor_heart,
                            color: plainWhite,
                            size: fontSize * 2.5,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: 'Active Reservations',
                              fontSize: fontSize + 6,
                              color: plainWhite,
                              isBold: true,
                              fontFamily: 'Bold',
                            ),
                            const SizedBox(height: 4),
                            TextWidget(
                              text:
                                  '${_activeReservations.length} reservation(s) today',
                              fontSize: fontSize + 1,
                              color: plainWhite.withOpacity(0.9),
                              fontFamily: 'Regular',
                            ),
                          ],
                        ),
                        const SizedBox(width: 50),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: plainWhite.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.today,
                                color: plainWhite,
                                size: fontSize * 1.5,
                              ),
                              const SizedBox(width: 12),
                              TextWidget(
                                text:
                                    'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                                fontSize: fontSize + 1,
                                color: plainWhite,
                                fontFamily: 'Medium',
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: plainWhite.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.refresh, color: plainWhite),
                            onPressed: _loadActiveReservations,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Reservations list
            Expanded(
              child: _activeReservations.isEmpty
                  ? _buildEmptyState(
                      Icons.event_busy,
                      'No active reservations',
                      'All reservations will appear here when they become active',
                      fontSize,
                    )
                  : GridView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _activeReservations.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                      ),
                      itemBuilder: (context, index) {
                        final reservation = _activeReservations[index];
                        final countdown =
                            _reservationCountdowns[reservation['id']];
                        final now = DateTime.now();

                        // Determine if reservation is upcoming or active
                        bool isActive = false;
                        bool isUpcoming = false;
                        try {
                          final dateStr = reservation['date'];
                          final timeStr =
                              reservation['timeSlot'] ?? reservation['time'];
                          final dateParts = dateStr.split('-');
                          final timeParts = timeStr.split(' ');
                          final hourMin = timeParts[0].split(':');
                          int hour = int.parse(hourMin[0]);
                          final minute = int.parse(hourMin[1]);

                          if (timeParts.length > 1) {
                            if (timeParts[1] == 'PM' && hour != 12)
                              hour += 12;
                            else if (timeParts[1] == 'AM' && hour == 12)
                              hour = 0;
                          }

                          final reservationTime = DateTime(
                            int.parse(dateParts[0]),
                            int.parse(dateParts[1]),
                            int.parse(dateParts[2]),
                            hour,
                            minute,
                          );

                          isActive = now.isAfter(reservationTime);
                          isUpcoming = !isActive;
                        } catch (e) {
                          print('Error parsing time: \$e');
                        }

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Transform.translate(
                            offset: Offset(0, index % 2 == 0 ? 0 : 5),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: plainWhite,
                                boxShadow: [
                                  BoxShadow(
                                    color: isActive
                                        ? palmGreen.withOpacity(0.2)
                                        : isUpcoming
                                            ? Colors.orange.withOpacity(0.2)
                                            : ashGray.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                border: Border.all(
                                  color: isActive
                                      ? palmGreen.withOpacity(0.5)
                                      : isUpcoming
                                          ? Colors.orange.withOpacity(0.5)
                                          : ashGray.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Table info with gradient
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppTheme.primaryColor,
                                                AppTheme.primaryColor
                                                    .withOpacity(0.8),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryColor
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.table_restaurant,
                                                color: plainWhite,
                                                size: fontSize + 2,
                                              ),
                                              const SizedBox(width: 8),
                                              TextWidget(
                                                text:
                                                    reservation['tableName'] ??
                                                        'Table',
                                                fontSize: fontSize + 2,
                                                color: plainWhite,
                                                isBold: true,
                                                fontFamily: 'Bold',
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Status badge with animation
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isActive
                                                  ? [
                                                      palmGreen,
                                                      palmGreen.withOpacity(0.8)
                                                    ]
                                                  : [
                                                      Colors.orange,
                                                      Colors.orange
                                                          .withOpacity(0.8)
                                                    ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isActive
                                                    ? palmGreen.withOpacity(0.3)
                                                    : Colors.orange
                                                        .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isActive
                                                    ? Icons.play_circle
                                                    : Icons.schedule,
                                                color: plainWhite,
                                                size: fontSize,
                                              ),
                                              const SizedBox(width: 6),
                                              TextWidget(
                                                text: isActive
                                                    ? 'ACTIVE'
                                                    : 'UPCOMING',
                                                fontSize: fontSize - 1,
                                                color: plainWhite,
                                                isBold: true,
                                                fontFamily: 'Bold',
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        // Countdown timer with gradient
                                        if (countdown != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isActive
                                                    ? [
                                                        festiveRed,
                                                        festiveRed
                                                            .withOpacity(0.8)
                                                      ]
                                                    : [
                                                        AppTheme.primaryColor,
                                                        AppTheme.primaryColor
                                                            .withOpacity(0.8)
                                                      ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isActive
                                                      ? festiveRed
                                                          .withOpacity(0.3)
                                                      : AppTheme.primaryColor
                                                          .withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isActive
                                                      ? Icons.timer
                                                      : Icons.schedule,
                                                  color: plainWhite,
                                                  size: fontSize + 2,
                                                ),
                                                const SizedBox(width: 8),
                                                TextWidget(
                                                  text: _formatDuration(
                                                      countdown),
                                                  fontSize: fontSize + 2,
                                                  color: plainWhite,
                                                  isBold: true,
                                                  fontFamily: 'Bold',
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            ashGray.withOpacity(0.3),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Reservation details
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildModernDetailRow(
                                                Icons.person,
                                                'Customer',
                                                reservation['userName'] ??
                                                    reservation['userEmail'] ??
                                                    'N/A',
                                                fontSize,
                                              ),
                                              const SizedBox(height: 12),
                                              _buildModernDetailRow(
                                                Icons.access_time,
                                                'Time',
                                                reservation[
                                                        'timeSlotDisplay'] ??
                                                    reservation['time'] ??
                                                    'N/A',
                                                fontSize,
                                              ),
                                              const SizedBox(height: 12),
                                              _buildModernDetailRow(
                                                Icons.people,
                                                'Table',
                                                reservation['tableName'] ??
                                                    'N/A',
                                                fontSize,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (reservation['orderDetails'] !=
                                                null ||
                                            reservation['orderId'] != null)
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.blue
                                                        .withOpacity(0.1),
                                                    Colors.blue
                                                        .withOpacity(0.05),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                    color: Colors.blue
                                                        .withOpacity(0.2)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.blue
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Icon(
                                                          Icons.restaurant_menu,
                                                          size: fontSize,
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      TextWidget(
                                                        text: 'Pre-Order',
                                                        fontSize: fontSize,
                                                        color: Colors.blue,
                                                        isBold: true,
                                                        fontFamily: 'Bold',
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextWidget(
                                                    text: reservation[
                                                            'orderDetails'] ??
                                                        'Order #${reservation['orderId']}',
                                                    fontSize: fontSize - 1,
                                                    color: textBlack,
                                                    fontFamily: 'Regular',
                                                  ),
                                                ],
                                              ),
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Build empty state widget
  Widget _buildEmptyState(
      IconData icon, String title, String subtitle, double fontSize) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: ashGray.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 80,
              color: ashGray.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          TextWidget(
            text: title,
            fontSize: fontSize + 4,
            color: charcoalGray,
            isBold: true,
            fontFamily: 'Bold',
          ),
          const SizedBox(height: 8),
          TextWidget(
            text: subtitle,
            fontSize: fontSize + 1,
            color: ashGray,
            fontFamily: 'Regular',
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build modern detail row
  Widget _buildModernDetailRow(
      IconData icon, String label, String value, double fontSize) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: fontSize,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: label,
                fontSize: fontSize - 2,
                color: ashGray,
                fontFamily: 'Regular',
              ),
              TextWidget(
                text: value,
                fontSize: fontSize,
                color: textBlack,
                isBold: true,
                fontFamily: 'Bold',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build history view
  Widget _buildHistoryView(BuildContext context, double screenWidth,
      double fontSize, double padding) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cloudWhite,
            plainWhite,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters with modern design
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: plainWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.filter_list,
                          color: plainWhite,
                          size: fontSize * 1.5,
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextWidget(
                        text: 'Filters',
                        fontSize: fontSize + 4,
                        color: textBlack,
                        isBold: true,
                        fontFamily: 'Bold',
                      ),
                      const SizedBox(width: 50),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: ashGray.withOpacity(0.2)),
                        ),
                        child: SizedBox(
                          width: 500,
                          child: DropdownButtonFormField<String>(
                            value: _historyFilter,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              labelStyle: TextStyle(
                                color: charcoalGray,
                                fontSize: fontSize,
                                fontFamily: 'Regular',
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                            ),
                            icon: Icon(Icons.arrow_drop_down,
                                color: AppTheme.primaryColor),
                            style: TextStyle(
                              color: textBlack,
                              fontSize: fontSize + 1,
                              fontFamily: 'Medium',
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'all',
                                child: Row(
                                  children: [
                                    Icon(Icons.list,
                                        color: AppTheme.primaryColor,
                                        size: fontSize),
                                    const SizedBox(width: 12),
                                    TextWidget(
                                      text: 'All Reservations',
                                      fontSize: fontSize,
                                      color: textBlack,
                                      fontFamily: 'Regular',
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'completed',
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: palmGreen, size: fontSize),
                                    const SizedBox(width: 12),
                                    TextWidget(
                                      text: 'Completed',
                                      fontSize: fontSize,
                                      color: textBlack,
                                      fontFamily: 'Regular',
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'cancelled',
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel,
                                        color: festiveRed, size: fontSize),
                                    const SizedBox(width: 12),
                                    TextWidget(
                                      text: 'Cancelled',
                                      fontSize: fontSize,
                                      color: textBlack,
                                      fontFamily: 'Regular',
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'expired',
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        color: Colors.orange, size: fontSize),
                                    const SizedBox(width: 12),
                                    TextWidget(
                                      text: 'Expired',
                                      fontSize: fontSize,
                                      color: textBlack,
                                      fontFamily: 'Regular',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _historyFilter = value!;
                              });
                              _loadReservationHistory();
                            },
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon:
                              Icon(Icons.refresh, color: AppTheme.primaryColor),
                          onPressed: _loadReservationHistory,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // History list
            Expanded(
              child: _reservationHistory.isEmpty
                  ? _buildEmptyState(
                      Icons.history,
                      'No reservation history',
                      'Past reservations will appear here once they are completed or cancelled',
                      fontSize,
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.2,
                      ),
                      padding: EdgeInsets.zero,
                      itemCount: _reservationHistory.length,
                      itemBuilder: (context, index) {
                        final reservation = _reservationHistory[index];
                        final status = reservation['status'] ?? 'unknown';

                        Color statusColor;
                        IconData statusIcon;
                        Color statusGradientStart;
                        Color statusGradientEnd;

                        switch (status) {
                          case 'completed':
                            statusColor = palmGreen;
                            statusIcon = Icons.check_circle;
                            statusGradientStart = palmGreen;
                            statusGradientEnd = palmGreen.withOpacity(0.7);
                            break;
                          case 'cancelled':
                            statusColor = festiveRed;
                            statusIcon = Icons.cancel;
                            statusGradientStart = festiveRed;
                            statusGradientEnd = festiveRed.withOpacity(0.7);
                            break;
                          case 'expired':
                            statusColor = Colors.orange;
                            statusIcon = Icons.access_time;
                            statusGradientStart = Colors.orange;
                            statusGradientEnd = Colors.orange.withOpacity(0.7);
                            break;
                          default:
                            statusColor = ashGray;
                            statusIcon = Icons.help;
                            statusGradientStart = ashGray;
                            statusGradientEnd = ashGray.withOpacity(0.7);
                        }

                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Transform.translate(
                            offset: Offset(0, index % 2 == 0 ? 0 : 5),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: plainWhite,
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Status icon with gradient
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            statusGradientStart,
                                            statusGradientEnd,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: statusColor.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        statusIcon,
                                        color: plainWhite,
                                        size: fontSize * 2,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // Reservation details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              TextWidget(
                                                text:
                                                    reservation['tableName'] ??
                                                        'Table',
                                                fontSize: fontSize + 2,
                                                color: textBlack,
                                                isBold: true,
                                                fontFamily: 'Bold',
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      statusColor
                                                          .withOpacity(0.2),
                                                      statusColor
                                                          .withOpacity(0.1),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: statusColor
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                child: TextWidget(
                                                  text: status.toUpperCase(),
                                                  fontSize: fontSize - 2,
                                                  color: statusColor,
                                                  isBold: true,
                                                  fontFamily: 'Bold',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          TextWidget(
                                            text: reservation['userName'] ??
                                                reservation['userEmail'] ??
                                                'N/A',
                                            fontSize: fontSize + 1,
                                            color: textBlack,
                                            fontFamily: 'Medium',
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: fontSize - 2,
                                                color: ashGray,
                                              ),
                                              const SizedBox(width: 4),
                                              TextWidget(
                                                text: reservation[
                                                        'dateDisplay'] ??
                                                    reservation['date'] ??
                                                    'N/A',
                                                fontSize: fontSize - 1,
                                                color: charcoalGray,
                                                fontFamily: 'Regular',
                                              ),
                                              const SizedBox(width: 16),
                                              Icon(
                                                Icons.access_time,
                                                size: fontSize - 2,
                                                color: ashGray,
                                              ),
                                              const SizedBox(width: 4),
                                              TextWidget(
                                                text: reservation[
                                                        'timeSlotDisplay'] ??
                                                    reservation['time'] ??
                                                    'N/A',
                                                fontSize: fontSize - 1,
                                                color: charcoalGray,
                                                fontFamily: 'Regular',
                                              ),
                                            ],
                                          ),
                                          if (reservation['orderDetails'] !=
                                                  null ||
                                              reservation['orderId'] !=
                                                  null) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.blue
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.restaurant_menu,
                                                    size: fontSize - 2,
                                                    color: Colors.blue,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  TextWidget(
                                                    text: reservation[
                                                            'orderDetails'] ??
                                                        'Order #${reservation['orderId']}',
                                                    fontSize: fontSize - 1,
                                                    color: Colors.blue,
                                                    fontFamily: 'Medium',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build detail row
  Widget _buildDetailRow(
      IconData icon, String label, String value, double fontSize) {
    return Row(
      children: [
        Icon(icon, size: fontSize, color: charcoalGray),
        const SizedBox(width: 8),
        TextWidget(
          text: '$label: ',
          fontSize: fontSize - 1,
          color: charcoalGray,
          fontFamily: 'Regular',
        ),
        Expanded(
          child: TextWidget(
            text: value,
            fontSize: fontSize - 1,
            color: textBlack,
            isBold: true,
            fontFamily: 'Bold',
          ),
        ),
      ],
    );
  }

  // Helper to format duration
  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Build modern status summary widget
  Widget _buildModernStatusSummary(double fontSize) {
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
        _buildModernStatusChip('Available', availableCount, palmGreen,
            Icons.check_circle, fontSize),
        const SizedBox(width: 8),
        _buildModernStatusChip('Reserved', reservedCount, AppTheme.primaryColor,
            Icons.event, fontSize),
        const SizedBox(width: 8),
        _buildModernStatusChip(
            'Disabled', disabledCount, festiveRed, Icons.block, fontSize),
      ],
    );
  }

  // Build modern status chip widget
  Widget _buildModernStatusChip(
      String label, int count, Color color, IconData icon, double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: fontSize - 2,
          ),
          const SizedBox(width: 6),
          TextWidget(
            text: '$label: ',
            fontSize: fontSize - 1,
            color: color,
            fontFamily: 'Medium',
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
}
