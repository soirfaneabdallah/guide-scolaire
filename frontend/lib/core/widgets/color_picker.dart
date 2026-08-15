// frontend/lib/core/widgets/color_picker.dart

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ColorPicker extends StatefulWidget {
  const ColorPicker({
    super.key,
    required this.selectedColor,
    this.onColorSelected,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
    this.itemSize = 36,
    this.showLabel = true,
  });

  final String selectedColor;
  final ValueChanged<String>? onColorSelected;
  final EdgeInsets padding;
  final double itemSize;
  final bool showLabel;

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.selectedColor;
  }

  @override
  Widget build(BuildContext context) {
    final colors = const [
      '#FF6B6B', '#FF9F43', '#FECA57', '#48DBFB',
      '#0ABDE3', '#10AC84', '#EE5A24', '#5F27CD',
      '#341F97', '#FF6FB7', '#F368E0', '#00D2D3',
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ✅ Rendre responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final itemSize = isMobile ? widget.itemSize * 0.85 : widget.itemSize;
    final spacing = isMobile ? 6.0 : 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '🎨 Couleur',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
          ),
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: colors.map((colorHex) {
            final isSelected = _selectedColor == colorHex;
            final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = colorHex);
                widget.onColorSelected?.call(colorHex);
              },
              child: Container(
                width: itemSize,
                height: itemSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: isMobile ? 1.5 : 2,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: isMobile ? 6 : 8,
                        spreadRadius: isMobile ? 1 : 2,
                      ),
                  ],
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: itemSize * 0.5,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}