import 'package:flutter/material.dart';
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
  // Sample available seats and time slots
  final List<Map<String, dynamic>> _availableSeats = [
    {
      'seat': 'Table 1',
      'capacity': 2,
      'available': true,
      'reservation': null,
    },
    {
      'seat': 'Table 2',
      'capacity': 4,
      'available': true,
      'reservation': null,
    },
    {
      'seat': 'Table 3',
      'capacity': 4,
      'available': false,
      'reservation': {
        'name': 'John Doe',
        'date': '9/7/2025',
        'time': '12:00 PM',
        'order': 'Latte, Croissant',
      },
    },
    {
      'seat': 'Table 4',
      'capacity': 6,
      'available': true,
      'reservation': null,
    },
    {
      'seat': 'Booth 1',
      'capacity': 4,
      'available': true,
      'reservation': null,
    },
    {
      'seat': 'Booth 2',
      'capacity': 6,
      'available': false,
      'reservation': {
        'name': 'Jane Smith',
        'date': '9/7/2025',
        'time': '2:00 PM',
        'order': 'Espresso, Muffin',
      },
    },
  ];

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

  // State variables
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String? _selectedSeat;
  int _numberOfGuests = 1;

  // Show date picker
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
        _selectedTime = null; // Reset time when date changes
        _selectedSeat = null; // Reset seat when date changes
      });
    }
  }

  // Show reservation details dialog
  void _showReservationDetails(
      BuildContext context, Map<String, dynamic> seat) {
    showDialog(
      context: context,
      builder: (context) {
        final reservation = seat['reservation'];

        print(reservation);
        final screenWidth = MediaQuery.of(context).size.width;
        final fontSize = screenWidth * 0.018;

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
              : Column(
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
                      text: 'Order: ${reservation['order']}',
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
              color: bayanihanBlue,
              textColor: plainWhite,
              fontSize: fontSize + 1,
              height: 45,
              width: 100,
              radius: 10,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.02; // Larger font for tablet
    final padding = screenWidth * 0.02;

    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: bayanihanBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        title: TextWidget(
          text: 'Reservations',
          fontSize: 24,
          fontFamily: 'Bold',
          color: Colors.white,
          isBold: true,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Date, Time, and Guests
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Selection
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
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
                  // Time Selection
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
                              _selectedSeat =
                                  null; // Reset seat when time changes
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
                  // Number of Guests
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
            // Right Column: Seat Selection and Confirmation
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
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // More columns for tablet
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio:
                          screenWidth * 0.25 / (screenWidth * 0.25),
                    ),
                    itemCount: _availableSeats.length,
                    itemBuilder: (context, index) {
                      final seat = _availableSeats[index];
                      final isSelected = _selectedSeat == seat['seat'];
                      final isAvailable = seat['available'];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: () {
                            print(seat);
                            // Show reservation details dialog
                            _showReservationDetails(context, seat);
                            // Existing selection logic
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
                                  color: isAvailable ? textBlack : charcoalGray,
                                  isBold: true,
                                  fontFamily: 'Bold',
                                ),
                                const SizedBox(height: 8),
                                TextWidget(
                                  text: 'Capacity: ${seat['capacity']} guests',
                                  fontSize: fontSize,
                                  color: isAvailable
                                      ? charcoalGray
                                      : charcoalGray.withOpacity(0.6),
                                  fontFamily: 'Regular',
                                ),
                                const SizedBox(height: 8),
                                TextWidget(
                                  text: isAvailable ? 'Available' : 'Occupied',
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
                  ),
                  const SizedBox(height: 20),
                  // Confirm Reservation Button
                  Center(
                    child: ButtonWidget(
                      label: 'Confirm Reservation',
                      onPressed: _selectedTime != null && _selectedSeat != null
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: TextWidget(
                                    text:
                                        'Reservation confirmed for $_selectedSeat at $_selectedTime on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    fontSize: fontSize,
                                    color: plainWhite,
                                    fontFamily: 'Regular',
                                  ),
                                  backgroundColor: bayanihanBlue,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              Navigator.pop(context);
                            }
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
            )
          ],
        ),
      ),
    );
  }
}
