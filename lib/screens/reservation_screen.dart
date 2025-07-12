import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
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
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String? _selectedSeat;
  int _numberOfGuests = 1;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  final List<String> _timeSlots = [
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize default values if needed
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
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
              primary: bayanihanBlue,
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
        _selectedTime = null;
        _selectedSeat = null;
        _nameController.clear();
        _orderController.clear();
        _numberOfGuests = 1;
      });
    }
  }

  void _showReservationDetails(
      BuildContext context, Map<String, dynamic> seat) {
    final reservation = seat['reservation'];
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.018;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: plainWhite,
        title: TextWidget(
          text: seat['seat'] +
              (seat['available'] ? ' (Available)' : ' (Occupied)'),
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
                      text: 'Name: ${reservation['name']}',
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
                      color: reservation['status'] == 'Confirmed'
                          ? bayanihanBlue
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
                  reservation['status'] == 'Confirmed' ? 'Cancel' : 'Confirm',
              onPressed: () async {
                try {
                  final newStatus = reservation['status'] == 'Confirmed'
                      ? 'Cancelled'
                      : 'Confirmed';
                  await _firestore
                      .collection('reservations')
                      .doc(seat['docId'])
                      .update({
                    'reservation.status': newStatus,
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
                      backgroundColor: bayanihanBlue,
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
              color: reservation['status'] == 'Confirmed'
                  ? festiveRed
                  : bayanihanBlue,
              textColor: plainWhite,
              fontSize: fontSize + 1,
              height: 45,
              width: 100,
              radius: 10,
            ),
          if (reservation != null)
            ButtonWidget(
              label: 'Edit',
              onPressed: () {
                Navigator.of(context).pop();
                _showEditReservationDialog(context, seat);
              },
              color: bayanihanBlue,
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
    if (_selectedTime == null || _selectedSeat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Please select a time and seat',
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
          text: 'Create Reservation for $_selectedSeat',
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
                    borderSide: BorderSide(color: bayanihanBlue, width: 2),
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
                    borderSide: BorderSide(color: bayanihanBlue, width: 2),
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
                final selectedSeatData =
                    allSeats.firstWhere((s) => s['seat'] == _selectedSeat);
                await _firestore.collection('reservations').add({
                  'seat': _selectedSeat,
                  'capacity': selectedSeatData['capacity'],
                  'available': false,
                  'reservation': {
                    'name': _nameController.text,
                    'date': DateFormat('dd/MM/yyyy').format(_selectedDate),
                    'time': _selectedTime,
                    'guests': _numberOfGuests,
                    'order': _orderController.text,
                    'status': 'Confirmed',
                    'source': 'POS', // Indicates reservation made via POS
                  },
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.of(context).pop();
                setState(() {
                  _selectedTime = null;
                  _selectedSeat = null;
                  _nameController.clear();
                  _orderController.clear();
                  _numberOfGuests = 1;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text:
                          'Reservation confirmed for $_selectedSeat at $_selectedTime',
                      fontSize: fontSize,
                      color: plainWhite,
                      fontFamily: 'Regular',
                    ),
                    backgroundColor: bayanihanBlue,
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
            color: bayanihanBlue,
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
      BuildContext context, Map<String, dynamic> seat) {
    final reservation = seat['reservation'];
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
          text: 'Edit Reservation for ${seat['seat']}',
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
                    borderSide: BorderSide(color: bayanihanBlue, width: 2),
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
                    borderSide: BorderSide(color: bayanihanBlue, width: 2),
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
                    .doc(seat['docId'])
                    .update({
                  'reservation.name': _nameController.text,
                  'reservation.order': _orderController.text,
                  'reservation.guests': _numberOfGuests,
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
                    backgroundColor: bayanihanBlue,
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
            color: bayanihanBlue,
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

  // Define the list of all possible seats
  final List<Map<String, dynamic>> allSeats = [
    {
      'seat': 'Table 1',
      'capacity': 2,
      'available': true,
      'reservation': null,
      'docId': null
    },
    {
      'seat': 'Table 2',
      'capacity': 4,
      'available': true,
      'reservation': null,
      'docId': null
    },
    {
      'seat': 'Table 3',
      'capacity': 4,
      'available': true,
      'reservation': null,
      'docId': null
    },
    {
      'seat': 'Table 4',
      'capacity': 6,
      'available': true,
      'reservation': null,
      'docId': null
    },
    {
      'seat': 'Booth 1',
      'capacity': 4,
      'available': true,
      'reservation': null,
      'docId': null
    },
    {
      'seat': 'Booth 2',
      'capacity': 6,
      'available': true,
      'reservation': null,
      'docId': null
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.02;
    final padding = screenWidth * 0.02;

    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: bayanihanBlue,
        foregroundColor: plainWhite,
        elevation: 4,
        title: TextWidget(
          text: 'Reservations',
          fontSize: 24,
          fontFamily: 'Bold',
          color: plainWhite,
          isBold: true,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
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
                            color: bayanihanBlue.withOpacity(0.1),
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
                            color: bayanihanBlue,
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
                    children: _timeSlots.map((time) {
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
                              _selectedSeat = null;
                            });
                          }
                        },
                        backgroundColor: cloudWhite,
                        selectedColor: bayanihanBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? bayanihanBlue : ashGray,
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
                        color: bayanihanBlue,
                        textColor: plainWhite,
                        fontSize: fontSize + 1,
                        height: 50,
                        width: 60,
                        radius: 10,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'Select Seat',
                    fontSize: 24,
                    color: textBlack,
                    isBold: true,
                    fontFamily: 'Bold',
                    letterSpacing: 1,
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('reservations')
                        .where('date',
                            isEqualTo:
                                DateFormat('dd/MM/yyyy').format(_selectedDate))
                        .where('time', isEqualTo: _selectedTime ?? '')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: TextWidget(
                            text: 'Error: ${snapshot.error}',
                            fontSize: fontSize,
                            color: festiveRed,
                            fontFamily: 'Regular',
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final reservedSeats = snapshot.data!.docs
                          .map((doc) => {
                                ...doc.data() as Map<String, dynamic>,
                                'docId': doc.id
                              })
                          .toList();
                      final seats = List<Map<String, dynamic>>.from(allSeats);
                      for (var seat in seats) {
                        final reserved = reservedSeats.firstWhere(
                          (r) => r['seat'] == seat['seat'],
                          orElse: () => {},
                        );
                        if (reserved.isNotEmpty) {
                          seat['available'] = false;
                          seat['reservation'] = reserved['reservation'];
                          seat['docId'] = reserved['docId'];
                        }
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio:
                              screenWidth * 0.25 / (screenWidth * 0.25),
                        ),
                        itemCount: seats.length,
                        itemBuilder: (context, index) {
                          final seat = seats[index];
                          final isSelected = _selectedSeat == seat['seat'];
                          final isAvailable = seat['available'] &&
                              _numberOfGuests <= seat['capacity'];
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: InkWell(
                              onTap: () {
                                _showReservationDetails(context, seat);
                                if (isAvailable && _selectedTime != null) {
                                  setState(() {
                                    _selectedSeat = seat['seat'];
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
                                        ? bayanihanBlue
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
                                      text: seat['seat'],
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
                                          'Capacity: ${seat['capacity']} guests',
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
                                          ? bayanihanBlue
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
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ButtonWidget(
                      label: 'Create Reservation',
                      onPressed: _selectedTime != null && _selectedSeat != null
                          ? () => _showCreateReservationDialog(context)
                          : () {},
                      color: _selectedTime != null && _selectedSeat != null
                          ? bayanihanBlue
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
      ),
    );
  }
}
