// frontend/lib/features/videos/presentation/widgets/video_suggestions.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class VideoSuggestions extends StatelessWidget {
  const VideoSuggestions({
    super.key,
    this.subjectName,
    required this.onSuggestionSelected,
  });

  final String? subjectName;
  final ValueChanged<String> onSuggestionSelected;

  // ✅ Suggestions par matière
  List<String> _getSuggestions() {
    final subject = subjectName?.toLowerCase() ?? '';

    if (subject.contains('math')) {
      return [
        'Explique le théorème de Pythagore',
        'Les fractions et leurs opérations',
        'Les équations du premier degré',
        'La fonction dérivée',
      ];
    }

    if (subject.contains('physique') || subject.contains('chimie')) {
      return [
        'La gravitation universelle',
        'Les réactions chimiques',
        'La loi d\'Ohm',
        'L\'énergie cinétique',
      ];
    }

    if (subject.contains('svt') || subject.contains('biologie')) {
      return [
        'La photosynthèse',
        'La division cellulaire',
        'Le cycle de l\'eau',
        'L\'ADN et les gènes',
      ];
    }

    if (subject.contains('français')) {
      return [
        'Les figures de style',
        'Le présent de l\'indicatif',
        'La dissertation littéraire',
        'Le commentaire de texte',
      ];
    }

    if (subject.contains('histoire') || subject.contains('géo')) {
      return [
        'La Première Guerre mondiale',
        'La mondialisation',
        'Les civilisations anciennes',
        'Le changement climatique',
      ];
    }

    if (subject.contains('anglais')) {
      return [
        'Le présent simple',
        'Les verbes irréguliers',
        'Le past perfect',
        'Les modaux',
      ];
    }

    // Par défaut
    return [
      'Un concept scientifique',
      'Une notion mathématique',
      'Un point de grammaire',
      'Un événement historique',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suggestions = _getSuggestions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              'Suggestions',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((suggestion) {
            return _buildSuggestionChip(
              suggestion: suggestion,
              isDark: isDark,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip({
    required String suggestion,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSuggestionSelected(suggestion),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: Text(
            suggestion,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textWhite : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}