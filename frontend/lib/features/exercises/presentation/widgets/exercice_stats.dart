// frontend/lib/features/exercices/presentation/widgets/exercice_stats.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/exercices_provider.dart';

class ExerciceStats extends StatelessWidget {
  const ExerciceStats({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExercicesProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Total',
            value: provider.totalExercices.toString(),
            icon: Icons.list_alt,
            color: AppColors.primary,
          ),
          _StatItem(
            label: 'Terminés',
            value: provider.completedExercices.toString(),
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
          _StatItem(
            label: 'En cours',
            value: provider.inProgressExercices.toString(),
            icon: Icons.pending,
            color: AppColors.warning,
          ),
          _StatItem(
            label: 'Progression',
            value: '${(provider.completionRate * 100).toInt()}%',
            icon: Icons.trending_up,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}