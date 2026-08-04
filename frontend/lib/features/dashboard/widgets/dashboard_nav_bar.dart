// frontend/lib/features/dashboard/presentation/widgets/dashboard_nav_bar.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DashboardNavBar extends StatelessWidget {
  const DashboardNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final Function(int) onTabSelected;

  static const List<Map<String, dynamic>> _tabs = [
    {'icon': Icons.school_outlined, 'label': 'Apprendre'},
    {'icon': Icons.autorenew_outlined, 'label': 'Réviser'},
    {'icon': Icons.edit_note_outlined, 'label': 'Exercices'},
    {'icon': Icons.draw_outlined, 'label': 'Cahier'},
    {'icon': Icons.chat_outlined, 'label': 'Chat'},
    {'icon': Icons.trending_up_outlined, 'label': 'Progression'},
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.3)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isSelected = selectedIndex == index;

            return _NavTab(
              icon: tab['icon'] as IconData,
              label: tab['label'] as String,
              isSelected: isSelected,
              onTap: () => onTabSelected(index),
              isMobile: isMobile,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isMobile,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: isMobile ? 18 : 20,
            ),
            if (!isMobile) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}