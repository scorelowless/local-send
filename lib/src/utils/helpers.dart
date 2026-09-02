import 'package:flutter/material.dart';

/// Small shared helper utilities used across UI code.

String colorToHex(Color c) =>
    '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

Color hexToColor(String hex) {
  final String cleaned = hex.replaceFirst('#', '');
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }
  if (cleaned.length == 8) {
    return Color(int.parse(cleaned, radix: 16));
  }
  return Colors.blue.shade200;
}
