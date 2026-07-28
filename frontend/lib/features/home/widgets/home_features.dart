// frontend/lib/features/home/widgets/home_features.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HomeFeatures extends StatelessWidget {
  const HomeFeatures({super.key});

  final List<Map<String, dynamic>> features = const [
    {
      'icon': Icons.chat_bubble_outline,
      'title': 'Chat Intelligent',
      'description': 'Pose tes questions et reçois des réponses claires, adaptées à ton niveau.',
      'color': AppColors.primary,
    },
    {
      'icon': Icons.book_outlined,
      'title': 'Cours Complets',
      'description': 'Tout le programme comorien, de la 6e à la Terminale, à portée de main.',
      'color': AppColors.accentBlue,
    },
    {
      'icon': Icons.edit_note_outlined,
      'title': 'Cahier Numérique',
      'description': 'Écris à la main comme sur une feuille, l\'IA te corrige en direct.',
      'color': AppColors.secondary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 60,
      ),
      color: AppColors.background,
      child: Column(
        children: [
          const Text(
            'Pourquoi choisir Guide Scolaire ?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Un outil pensé pour les élèves comoriens, par des Comoriens',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          if (isMobile)
            Column(
              children: features.map((f) => _FeatureCard(feature: f)).toList(),
            )
          else
            Row(
              children: features
                  .map((f) => Expanded(child: _FeatureCard(feature: f)))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final Map<String, dynamic> feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (feature['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              feature['icon'] as IconData,
              color: feature['color'] as Color,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            feature['title'] as String,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            feature['description'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}