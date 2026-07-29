// frontend/lib/features/dashboard/widgets/dashboard_quick_actions.dart

import 'package:flutter/material.dart';
import '../../../../core/routing/app_routes.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  final List<Map<String, dynamic>> actions = const [
    {'icon': '📖', 'label': 'Cours', 'route': AppRoutes.courses},
    {'icon': '✍️', 'label': 'Exercices', 'route': AppRoutes.exercises},
    {'icon': '🖍️', 'label': 'Cahier', 'route': AppRoutes.handwriting},
    {'icon': '📊', 'label': 'Progression', 'route': null},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions.map((action) {
        return InkWell(
          onTap: () {
            if (action['route'] != null) {
              Navigator.pushNamed(context, action['route']);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              children: [
                Text(
                  action['icon'] as String,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  action['label'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}