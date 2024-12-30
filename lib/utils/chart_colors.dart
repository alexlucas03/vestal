import 'package:flutter/material.dart';

class ChartColors {
  static Color getUserColor(bool isPinkPreference) {
    return isPinkPreference ? Colors.pink : const Color(0xFF3A4C7A);
  }

  static Color getPartnerColor(bool isPinkPreference) {
    return isPinkPreference ? const Color(0xFF3A4C7A) : Colors.pink;
  }
}