import 'package:flutter/material.dart';

class SkillMatchTheme {
  static const LinearGradient menuGradient = LinearGradient(
    colors: [Color(0xFF7EC8FF), Color(0xFF4EA8FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData light() {
    return ThemeData(
      colorSchemeSeed: const Color(0xFF1565C0),
      useMaterial3: true,
      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerColor: Color(0x66FFFFFF),
    );
  }
}
