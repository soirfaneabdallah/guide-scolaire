// frontend/lib/features/dashboard/presentation/widgets/dashboard_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<DashboardProvider>(context);
    final userName = auth.userName ?? 'Élève';

    return Drawer(
      width: 280,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header profil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    auth.userLevel ?? 'Collège',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Accueil
            _DrawerItem(
              icon: Icons.home_outlined,
              label: 'Accueil',
              isSelected: provider.selectedIndex == 0 && provider.selectedSubject == 'home',
              onTap: () {
                provider.selectTab(0);
                Navigator.pop(context);
              },
            ),

            const Divider(height: 1, color: AppColors.divider),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MATIÈRES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Liste des matières
            _SubjectListTile(
              emoji: '📐',
              label: 'Maths',
              subjectId: 'maths',
              isSelected: provider.selectedSubject == 'maths',
              onTap: () {
                provider.selectSubject('maths');
                Navigator.pop(context);
              },
            ),
            _SubjectListTile(
              emoji: '📖',
              label: 'Français',
              subjectId: 'francais',
              isSelected: provider.selectedSubject == 'francais',
              onTap: () {
                provider.selectSubject('francais');
                Navigator.pop(context);
              },
            ),
            _SubjectListTile(
              emoji: '⚡',
              label: 'Physique',
              subjectId: 'physique',
              isSelected: provider.selectedSubject == 'physique',
              onTap: () {
                provider.selectSubject('physique');
                Navigator.pop(context);
              },
            ),
            _SubjectListTile(
              emoji: '🧬',
              label: 'SVT',
              subjectId: 'svt',
              isSelected: provider.selectedSubject == 'svt',
              onTap: () {
                provider.selectSubject('svt');
                Navigator.pop(context);
              },
            ),
            _SubjectListTile(
              emoji: '🏛️',
              label: 'Histoire',
              subjectId: 'histoire',
              isSelected: provider.selectedSubject == 'histoire',
              onTap: () {
                provider.selectSubject('histoire');
                Navigator.pop(context);
              },
            ),
            _SubjectListTile(
              emoji: '🗣️',
              label: 'Anglais',
              subjectId: 'anglais',
              isSelected: provider.selectedSubject == 'anglais',
              onTap: () {
                provider.selectSubject('anglais');
                Navigator.pop(context);
              },
            ),

            const Divider(height: 1, color: AppColors.divider),

            // Exercices
            _DrawerItem(
              icon: Icons.edit_note_outlined,
              label: 'Exercices',
              isSelected: provider.selectedIndex == 2,
              onTap: () {
                provider.selectTab(2);
                Navigator.pop(context);
              },
            ),

            // Cahier
            _DrawerItem(
              icon: Icons.draw_outlined,
              label: 'Cahier de correction',
              isSelected: provider.selectedIndex == 3,
              onTap: () {
                provider.selectTab(3);
                Navigator.pop(context);
              },
            ),

            const Spacer(),

            // Déconnexion
            ListTile(
              leading: const Icon(Icons.logout_outlined, color: AppColors.error),
              title: const Text(
                'Déconnexion',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                // Logique de déconnexion
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

class _SubjectListTile extends StatelessWidget {
  const _SubjectListTile({
    required this.emoji,
    required this.label,
    required this.subjectId,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final String subjectId;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 18)),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}