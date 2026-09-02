import 'package:flutter/material.dart';

/// Grid of selectable color swatches.
class SwatchGrid extends StatelessWidget {
  const SwatchGrid({
    super.key,
    required this.swatches,
    required this.selected,
    required this.onPick,
    this.size = 36,
  });

  final List<Color> swatches;
  final Color selected;
  final void Function(Color) onPick;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: swatches.map((col) {
        final isSel = col.value == selected.value;
        return GestureDetector(
          onTap: () => onPick(col),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: col,
              borderRadius: BorderRadius.circular(6),
              border: isSel ? Border.all(width: 2) : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
