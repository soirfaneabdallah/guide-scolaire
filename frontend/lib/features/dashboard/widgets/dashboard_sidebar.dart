// frontend/lib/features/dashboard/presentation/widgets/dashboard_sidebar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
    this.isCompact = false,
  });

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<DashboardProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = auth.userName ?? 'Élève';

    return Container(
      width: isCompact ? 72 : 260,
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Column(
        children: [
          // ===== Logo =====
          Container(
            padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 20),
            child: isCompact
                ? Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('📚', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('📚', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'E-learningAI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textWhite : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // ===== Menu =====
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 8),
              children: [
                // Accueil
                _SidebarItem(
                  icon: Icons.home_outlined,
                  label: 'Accueil',
                  isCompact: isCompact,
                  isDark: isDark,
                  isSelected: provider.selectedIndex == 0,
                  onTap: () => provider.selectTab(0),
                ),
                SizedBox(height: isCompact ? 4 : 8),

                // Section Matières
                if (!isCompact)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'MATIÈRES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textTertiary : AppColors.textTertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                ...provider.subjects.map((subject) {
                  return _SubjectItem(
                    label: subject.name,
                    isCompact: isCompact,
                    isDark: isDark,
                    isSelected: provider.selectedSubjectSlug == subject.slug && provider.selectedIndex == 0,
                    onTap: () {
                      provider.selectSubject(subject.slug);
                    },
                  );
                }).toList(),

                SizedBox(height: isCompact ? 4 : 16),

                // Exercices
                _SidebarItem(
                  icon: Icons.edit_note_outlined,
                  label: 'Exercices',
                  isCompact: isCompact,
                  isDark: isDark,
                  isSelected: provider.selectedIndex == 2,
                  onTap: () => provider.selectTab(2),
                ),

                // Cahier
                _SidebarItem(
                  icon: Icons.draw_outlined,
                  label: 'Cahier de correction',
                  isCompact: isCompact,
                  isDark: isDark,
                  isSelected: provider.selectedIndex == 3,
                  onTap: () => provider.selectTab(3),
                ),

                // 👇 BIBLIOTHÈQUE (AJOUTÉ)
                _SidebarItem(
                  icon: Icons.library_books_outlined,
                  label: 'Bibliothèque',
                  isCompact: isCompact,
                  isDark: isDark,
                  isSelected: provider.selectedIndex == 4,
                  onTap: () => provider.selectTab(4),
                ),
              ],
            ),
          ),

          // ===== Profil en bas =====
          const Divider(height: 1, color: AppColors.divider),
          Container(
            padding: EdgeInsets.all(isCompact ? 8 : 16),
            child: isCompact
                ? Center(
                    child: Tooltip(
                      message: userName,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              auth.userLevel ?? 'Collège',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.logout_outlined,
                          size: 16,
                          color: isDark ? AppColors.textWhite : AppColors.textSecondary,
                        ),
                        onPressed: () => _showLogoutDialog(context),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              auth.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

// ===== Widget SidebarItem =====
class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isCompact,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isCompact;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textWhite : AppColors.textSecondary;

    final listTile = ListTile(
      minLeadingWidth: isCompact ? 0 : 32,
      horizontalTitleGap: isCompact ? 0 : 12,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: 0,
      ),
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : textColor,
        size: isCompact ? 24 : 20,
      ),
      title: isCompact
          ? null
          : Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : textColor,
              ),
            ),
      trailing: (!isCompact && isSelected)
          ? Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : null,
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return isCompact
        ? Tooltip(
            message: label,
            child: listTile,
          )
        : listTile;
  }
}

// ===== Widget SubjectItem =====
class _SubjectItem extends StatelessWidget {
  const _SubjectItem({
    required this.label,
    required this.isCompact,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isCompact;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textWhite : AppColors.textSecondary;

    final listTile = ListTile(
      minLeadingWidth: isCompact ? 0 : 32,
      horizontalTitleGap: isCompact ? 0 : 12,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: 0,
      ),
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.textTertiary.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),
      title: isCompact
          ? null
          : Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : textColor,
              ),
            ),
      trailing: (!isCompact && isSelected)
          ? Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : null,
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return isCompact
        ? Tooltip(
            message: label,
            child: listTile,
          )
        : listTile;
  }
}