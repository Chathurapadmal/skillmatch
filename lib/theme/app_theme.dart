import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgDark = Color(0xFF0F1026);
  static const Color bgCard = Color(0xFF17193A);

  static const Color textPrimary = Color(0xFFF7F8FF);
  static const Color textSecondary = Color(0xFFC3C8F6);
  static const Color textMuted = Color(0xFF9AA3D6);

  static const Color primary = Color(0xFF4E7BFF);
  static const Color primaryLight = Color(0xFF7FA3FF);
  static const Color accent = Color(0xFF8A5BFF);
  static const Color accentLight = Color(0xFFB59CFF);

  static const Color success = Color(0xFF18C17C);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF5F6D);
  static const Color info = Color(0xFF3EA8FF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4E7BFF), Color(0xFF8A5BFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF17193A), Color(0xFF11132C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
