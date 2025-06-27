import 'package:flutter/material.dart';

const Color sunshineYellow = Color(0xFFFFD400);
const Color bayanihanBlue = Color(0xFF6689A7);
const Color primaryBlue = Color(0xFF6689A7);
const Color festiveRed = Color(0xFFD32F2F);
const Color palmGreen = Color(0xFF388E3C);
const Color cloudWhite = Color(0xFFF5F5F5);
const Color textBlack = Color(0xFF212121);
const Color accentOrange = Color(0xFFFF6D00);
const Color charcoalGray = Color(0xFF424242);
const Color ashGray = Color(0xFFB0BEC5);
const Color jetBlack = Color(0xFF000000);
const Color plainWhite = Color.fromARGB(255, 255, 255, 255);
TimeOfDay parseTime(String timeString) {
  List<String> parts = timeString.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}
