// frontend/lib/features/home/widgets/home_news.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HomeNews extends StatelessWidget {
  const HomeNews({super.key});

  final List<Map<String, String>> news = const [
    {
      'date': '28/07/2026',
      'title': 'Nouveau programme de Maths disponible',
      'description': 'Le programme de Terminale C a été mis à jour avec des exercices inédits.',
    },
    {
      'date': '25/07/2026',
      'title': 'Stage de perfectionnement à Moroni',
      'description': 'Du 10 au 20 août, un stage de maths et de français aura lieu au lycée de Bambao.',
    },
    {
      'date': '22/07/2026',
      'title': 'Guide Scolaire fête ses 200 utilisateurs',
      'description': 'Déjà 200 élèves utilisent l\'application ! Merci pour votre confiance.',
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
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.newspaper, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Actualités',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Restez informé des dernières nouveautés du monde éducatif aux Comores',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          if (isMobile)
            Column(
              children: news.map((n) => _NewsCard(news: n)).toList(),
            )
          else
            Row(
              children: news
                  .map((n) => Expanded(child: _NewsCard(news: n)))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news});

  final Map<String, String> news;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            news['date']!,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            news['title']!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            news['description']!,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}