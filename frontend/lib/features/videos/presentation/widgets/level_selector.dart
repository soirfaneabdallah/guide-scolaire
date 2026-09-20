// frontend/lib/features/videos/presentation/widgets/level_selector.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class LevelSelector extends StatelessWidget {
  const LevelSelector({
    super.key,
    required this.selectedLevel,
    required this.userLevel,
    required this.onLevelChanged,
  });

  final String selectedLevel;
  final String userLevel;
  final ValueChanged<String> onLevelChanged;

  static const List<String> _college = ['6ème', '5ème', '4ème', '3ème'];
  static const List<String> _lycee = ['Seconde', 'Première', 'Terminale'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 🎓 Niveaux Collège
            ..._college.map((level) => _buildChip(
                  level: level,
                  isSelected: level == selectedLevel,
                  isUserLevel: level == userLevel,
                  isDark: isDark,
                )),
            // Séparateur
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
            // 🎓 Niveaux Lycée
            ..._lycee.map((level) => _buildChip(
                  level: level,
                  isSelected: level == selectedLevel,
                  isUserLevel: level == userLevel,
                  isDark: isDark,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String level,
    required bool isSelected,
    required bool isUserLevel,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: () => onLevelChanged(level),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.transparent : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: isUserLevel && !isSelected
                ? Border.all(color: AppColors.primary.withOpacity(0.4))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isUserLevel)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.star,
                    size: 12,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              Text(
                level,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textWhite : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}