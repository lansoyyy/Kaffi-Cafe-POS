import 'package:flutter/material.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/widgets/drawer_widget.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:table_calendar/table_calendar.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: bayanihanBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        title: TextWidget(
          text: 'Transactions',
          fontSize: 20,
          fontFamily: 'Bold',
          color: Colors.white,
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                color: Colors.white,
                elevation: 3,
                child: SizedBox(
                  height: 400,
                  child: TableCalendar(
                    firstDay: DateTime.utc(2010, 10, 16),
                    lastDay: DateTime.utc(2050, 3, 14),
                    focusedDay: DateTime.now(),
                    calendarStyle: const CalendarStyle(
                      cellMargin: EdgeInsets.zero,
                      cellPadding: EdgeInsets.zero,
                      tablePadding: EdgeInsets.zero,
                      outsideDaysVisible: false,
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      leftChevronMargin: EdgeInsets.zero,
                      rightChevronMargin: EdgeInsets.zero,
                      headerPadding: EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      print(selectedDay.day);
                    },
                    availableGestures: AvailableGestures.horizontalSwipe,
                    calendarFormat: CalendarFormat.month,
                    rowHeight: 40,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                color: Colors.white,
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              shape: BoxShape.rectangle,
                              color: bayanihanBlue.withOpacity(0.5),
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.download,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: 'Coffee',
                                fontSize: 20,
                                fontFamily: 'Bold',
                                color: bayanihanBlue,
                              ),
                              const SizedBox(height: 12),
                              Table(
                                border: TableBorder.all(
                                  color: bayanihanBlue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(3),
                                  1: FlexColumnWidth(2),
                                  2: FlexColumnWidth(2),
                                  3: FixedColumnWidth(60),
                                },
                                children: [
                                  _buildTableHeader(),
                                  _buildTableRow('Espresso', 2, 120.00),
                                  _buildTableRow('Latte', 3, 150.00),
                                  _buildTableRow('Cappuccino', 1, 140.00),
                                ],
                              ),
                              const SizedBox(height: 24),
                              TextWidget(
                                text: 'Breads',
                                fontSize: 20,
                                fontFamily: 'Bold',
                                color: bayanihanBlue,
                              ),
                              const SizedBox(height: 12),
                              Table(
                                border: TableBorder.all(
                                  color: bayanihanBlue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(3),
                                  1: FlexColumnWidth(2),
                                  2: FlexColumnWidth(2),
                                  3: FixedColumnWidth(60),
                                },
                                children: [
                                  _buildTableHeader(),
                                  _buildTableRow('Croissant', 4, 80.00),
                                  _buildTableRow('Baguette', 2, 100.00),
                                  _buildTableRow('Sourdough', 1, 120.00),
                                ],
                              ),
                              const SizedBox(height: 24),
                              TextWidget(
                                text: 'Pastries',
                                fontSize: 20,
                                fontFamily: 'Bold',
                                color: bayanihanBlue,
                              ),
                              const SizedBox(height: 12),
                              Table(
                                border: TableBorder.all(
                                  color: bayanihanBlue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(3),
                                  1: FlexColumnWidth(2),
                                  2: FlexColumnWidth(2),
                                  3: FixedColumnWidth(60),
                                },
                                children: [
                                  _buildTableHeader(),
                                  _buildTableRow('Danish', 3, 90.00),
                                  _buildTableRow('Muffin', 5, 70.00),
                                  _buildTableRow('Scone', 2, 85.00),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: BoxDecoration(
        color: bayanihanBlue.withOpacity(0.1),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: 'Item',
            fontSize: 16,
            fontFamily: 'Bold',
            color: bayanihanBlue,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: 'Qty',
            fontSize: 16,
            fontFamily: 'Bold',
            color: bayanihanBlue,
            align: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: 'Price',
            fontSize: 16,
            fontFamily: 'Bold',
            color: bayanihanBlue,
            align: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: '',
            fontSize: 16,
            fontFamily: 'Bold',
            color: bayanihanBlue,
            align: TextAlign.center,
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String item, int quantity, double price) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: item,
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.grey[800],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: quantity.toString(),
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.grey[800],
            align: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextWidget(
            text: '₱${price.toStringAsFixed(2)}',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.grey[800],
            align: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: Icon(
              Icons.delete,
              color: festiveRed,
              size: 20,
            ),
            onPressed: () {
              // Placeholder for delete transaction logic
              print('Delete transaction for $item');
            },
          ),
        ),
      ],
    );
  }
}
