import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFF57D0A);
  static const Color background = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF8F8F8);
  static const Color border = Color(0xFFE7E7E7);

  static const Color textPrimary = Color(0xFF171717);
  static const Color textSecondary = Color(0xFF6B6B6B);

  // Subtle status colors — use sparingly
  static const Color success = Color(0xFF2E8B57);
  static const Color successLight = Color(0xFFEAF6EF);
  static const Color error = Color(0xFFD64545);
  static const Color errorLight = Color(0xFFFBEAEA);

  // Chip / selected states
  static const Color primaryLight = Color(
    0xFFFDECDC,
  ); // light orange bg for selected chips

  // Unread notification background
  static const Color unreadBackground = Color(0xFFFFF6EC);
}
