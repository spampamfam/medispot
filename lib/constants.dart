// lib/constants.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1D2671);
  static const Color secondaryColor = Color(0xFFC33764);
  static const Color accentColor = Color(0xFFF27121);
  static const Color backgroundColor = Color(0xFFF6F6F6);

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFFF27121), Color(0xFFE94057)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxDecoration getBoxDecoration() {
    return BoxDecoration(
      gradient: backgroundGradient,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 15,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}
