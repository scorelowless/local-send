import 'package:flutter/material.dart';
import '../utils/helpers.dart' as utils;

/// Reusable color widgets used across the app.
class ColorSquare extends StatelessWidget {
  const ColorSquare({super.key, required this.color, this.size = 36.0, this.margin});

  final Color color;
  final double size;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}

PopupMenuItem<String> buildColorMenuItem(Color color) {
  final String hex = utils.colorToHex(color);
  return PopupMenuItem<String>(
    value: hex,
    padding: const EdgeInsets.all(6),
    child: SizedBox(
      width: 44,
      height: 44,
      child: Center(child: ColorSquare(color: color)),
    ),
  );
}
