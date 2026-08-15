// frontend/lib/core/widgets/icon_picker.dart

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class IconPicker extends StatefulWidget {
  const IconPicker({
    super.key,
    required this.selectedIcon,
    this.onIconSelected,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
    this.itemSize = 44,
    this.showLabel = true,
    this.showSearch = true,
  });

  final String selectedIcon;
  final ValueChanged<String>? onIconSelected;
  final EdgeInsets padding;
  final double itemSize;
  final bool showLabel;
  final bool showSearch;

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
  late String _selectedIcon;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.selectedIcon;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ✅ Rendre responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final itemSize = isMobile ? widget.itemSize * 0.8 : widget.itemSize;
    final spacing = isMobile ? 4.0 : 6.0;

    final icons = _getPopularIcons();
    final displayedIcons = _searchQuery.isEmpty
        ? icons
        : icons.where((icon) => icon.contains(_searchQuery)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '😊 Icône',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
          ),
        if (widget.showSearch && !isMobile)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: '🔍 Rechercher une icône...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
            ),
          ),
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: displayedIcons.map((icon) {
            final isSelected = _selectedIcon == icon;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedIcon = icon);
                widget.onIconSelected?.call(icon);
              },
              child: Container(
                width: itemSize,
                height: itemSize,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15)
                      : isDark
                          ? Colors.grey[800]
                          : Colors.grey[50],
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : isDark
                            ? Colors.grey[700]!
                            : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: isMobile ? 4 : 8,
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: TextStyle(
                      fontSize: itemSize * 0.5,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (displayedIcons.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'Aucune icône trouvée',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<String> _getPopularIcons() {
    return const [
      '📚', '📐', '📖', '⚡', '🧬', '🏛️', '🗣️',
      '🎨', '🎵', '💻', '🧪', '🌍', '💭', '🧠',
      '📊', '⚖️', '🎓', '🔬', '✏️', '📝', '🧮',
      '🌌', '🏗️', '🎭', '💡', '🔍', '📋', '🔢',
      '🧩', '🔬', '🧪', '📡', '🤖', '💻', '📱',
      '🌐', '🔒', '🎯', '💪', '🌟', '✨', '🎉',
    ];
  }
}