// frontend/lib/features/home/widgets/home_drawer.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'home_menu_items.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // En-tête du drawer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '📚',
                        style: TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'E-learningAI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Comores',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Liste des éléments de navigation
            ...HomeMenuItems.items.map((item) {
              return ListTile(
                leading: Icon(
                  _getIconForRoute(item['route']!),
                  color: AppColors.primary,
                ),
                title: Text(
                  item['label']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Naviguer vers la route correspondante
                },
              );
            }).toList(),

            const Divider(),

            // Boutons Connexion / Inscription dans le drawer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Se connecter'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('S\'inscrire'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _getIconForRoute(String route) {
  switch (route) {
    case '/':
      return Icons.home_outlined;
    case '/features':
      return Icons.grid_view_outlined;
    case '/about':
      return Icons.info_outline;
    case '/contact':
      return Icons.mail_outline;
    default:
      return Icons.circle_outlined;
  }
}