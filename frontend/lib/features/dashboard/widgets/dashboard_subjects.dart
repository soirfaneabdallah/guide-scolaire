// frontend/lib/features/dashboard/widgets/dashboard_subjects.dart

import 'package:flutter/material.dart';

class DashboardSubjects extends StatelessWidget {
  const DashboardSubjects({super.key});

  final List<Map<String, dynamic>> subjects = const [
    {'name': 'Mathématiques', 'icon': '📐', 'color': 0xFF4CAF50},
    {'name': 'Français', 'icon': '📖', 'color': 0xFF2196F3},
    {'name': 'Physique', 'icon': '⚡', 'color': 0xFFFF9800},
    {'name': 'SVT', 'icon': '🧬', 'color': 0xFF9C27B0},
    {'name': 'Histoire', 'icon': '🏛️', 'color': 0xFF795548},
    {'name': 'Anglais', 'icon': '🗣️', 'color': 0xFFF44336},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📚 Mes matières',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E2937),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return InkWell(
              onTap: () {
                // TODO: Naviguer vers les cours de la matière
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(subject['color'] as int).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(subject['color'] as int).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      subject['icon'] as String,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject['name'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E2937),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}