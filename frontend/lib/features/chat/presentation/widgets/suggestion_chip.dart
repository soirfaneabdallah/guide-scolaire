// frontend/lib/features/chat/presentation/widgets/suggestion_chip.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Chip de suggestion pour les réponses de l'assistant.
class SuggestionChip extends StatelessWidget {
  const SuggestionChip({
    super.key,
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Suggestion: $label',
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: AppColors.background,
        side: const BorderSide(
          color: AppColors.divider,
          width: 1,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}