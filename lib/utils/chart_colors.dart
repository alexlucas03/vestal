import 'package:flutter/material.dart';

class ChartColors {
  static Color getUserColor(bool isPinkPreference) {
    return isPinkPreference ? Colors.pink : const Color(0xFF222D49);
  }

  static Color getPartnerColor(bool isPinkPreference) {
    return isPinkPreference ? const Color(0xFF222D49) : Colors.pink;
  }
}