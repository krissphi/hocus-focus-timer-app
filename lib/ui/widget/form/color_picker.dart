import 'package:flutter/material.dart';
import 'package:timtam/ui/utils/task_color_palette.dart';

class ColorPickerWidget extends StatelessWidget {
  const ColorPickerWidget({
    super.key,
    required this.selectedColorValue,
    required this.onColorChanged,
  });

  final int selectedColorValue;
  final Function(int) onColorChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity Color', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TaskColorPalette.colors.map((color) {
            final isSelected = selectedColorValue == color.toARGB32();
            return InkWell(
              onTap: () {
                onColorChanged(color.toARGB32());
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.black.withAlpha(153)
                        : Colors.white,
                    width: isSelected ? 2 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
