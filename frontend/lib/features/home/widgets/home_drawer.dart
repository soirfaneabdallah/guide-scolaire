// frontend/lib/features/home/widgets/home_drawer.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/routing/app_router.dart';
import 'home_menu_items.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Drawer(
      width: isMobile ? null : 320,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // ============================================================
            //  ZONE DE DÉGAGEMENT (SANS EN-TÊTE)
            // ============================================================
            const SizedBox(height: 16),

            // ============================================================
            //  MENU DE NAVIGATION
            // ============================================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  ...HomeMenuItems.items.map((item) {
                    final isSelected = item['route'] == '/';
                    return ListTile(
                      leading: Icon(
                        _getIconForRoute(item['route']!),
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        size: 22,
                      ),
                      title: Text(
                        item['label']!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        // Navigation
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      selected: isSelected,
                      selectedTileColor: AppColors.primary.withOpacity(0.08),
                    );
                  }).toList(),

                  const Divider(height: 32),

                  // ============================================================
                  //  BOUTONS CONNEXION / INSCRIPTION
                  // ============================================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              AppRouter.pushNamed(context, AppRoutes.login);
                            },
                            icon: const Icon(Icons.login_outlined, size: 18),
                            label: const Text(
                              'Se connecter',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              AppRouter.pushNamed(context, AppRoutes.register);
                            },
                            icon: const Icon(Icons.person_add_outlined, size: 18, color: Colors.white),
                            label: const Text(
                              'S\'inscrire',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ============================================================
            //  FOOTER
            // ============================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.copyright_outlined,
                    size: 12,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '2026 E-learningAI',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
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