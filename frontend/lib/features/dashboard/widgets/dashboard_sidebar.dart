// frontend/lib/features/dashboard/presentation/widgets/dashboard_sidebar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
//import '../screens/subject_management_screen.dart';


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
    final subjects = provider.subjects;

    return Container(
      width: isCompact ? 72 : 260,
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Column(
        children: [
          // ===== Logo =====
          _buildLogo(isDark),
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

                // 👇 BOUTON AJOUTER UNE MATIÈRE
                _AddSubjectButton(
                  isCompact: isCompact,
                  isDark: isDark,
                  onTap: () {
                    _showAddSubjectDialog(context, provider);
                  },
                ),
                SizedBox(height: isCompact ? 4 : 8),

                // Section Matières (DYNAMIQUE)
                if (!isCompact)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'MATIÈRES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textTertiary : AppColors.textTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        if (provider.isLoading)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),

                // Liste des matières
                if (provider.isLoading && subjects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                else if (subjects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Aucune matière',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textTertiary : AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ...subjects.map((subject) {
                    return _SubjectItem(
                      subject: subject,
                      isCompact: isCompact,
                      isDark: isDark,
                      isSelected: provider.selectedSubjectSlug == subject.slug && provider.selectedIndex == 0,
                      onTap: () {
                        provider.selectSubject(subject.slug);
                      },
                      onEdit: () {
                        _showEditSubjectDialog(context, provider, subject);
                      },
                      onDelete: () {
                        _showDeleteSubjectDialog(context, provider, subject);
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

                // Bibliothèque
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
          _buildProfile(isDark, userName, context),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Container(
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
    );
  }

  Widget _buildProfile(bool isDark, String userName, BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Column(
      children: [
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

  // ============================================================
  //  DIALOGUES CONNECTÉS AU PROVIDER
  // ============================================================

  void _showAddSubjectDialog(BuildContext context, DashboardProvider provider) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController iconController = TextEditingController();
    final TextEditingController colorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une matière'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la matière *',
                hintText: 'Ex: Informatique',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icône (emoji)',
                hintText: 'Ex: 💻',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: colorController,
              decoration: const InputDecoration(
                labelText: 'Couleur (hexadécimal)',
                hintText: 'Ex: #FF5722',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un nom'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final success = await provider.addSubject(
                name: nameController.text.trim(),
                icon: iconController.text.trim().isEmpty ? null : iconController.text.trim(),
                color: colorController.text.trim().isEmpty ? null : colorController.text.trim(),
              );

              if (!context.mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? '✅ Matière ajoutée avec succès' : '❌ ${provider.error ?? "Erreur"}',
                  ),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditSubjectDialog(BuildContext context, DashboardProvider provider, Subject subject) {
    final TextEditingController nameController = TextEditingController(text: subject.name);
    final TextEditingController iconController = TextEditingController(text: subject.icon ?? '');
    final TextEditingController colorController = TextEditingController(text: subject.color ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier ${subject.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la matière *',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icône (emoji)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: colorController,
              decoration: const InputDecoration(
                labelText: 'Couleur (hexadécimal)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un nom'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final success = await provider.updateSubject(
                subjectId: subject.id,
                name: nameController.text.trim(),
                icon: iconController.text.trim().isEmpty ? null : iconController.text.trim(),
                color: colorController.text.trim().isEmpty ? null : colorController.text.trim(),
              );

              if (!context.mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? '✅ Matière modifiée' : '❌ ${provider.error ?? "Erreur"}',
                  ),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSubjectDialog(BuildContext context, DashboardProvider provider, Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ${subject.name}'),
        content: Text(
          'Voulez-vous vraiment supprimer la matière "${subject.name}" ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final success = await provider.deleteSubject(subject.id);

              if (!context.mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? '✅ Matière supprimée' : '❌ ${provider.error ?? "Erreur"}',
                  ),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                : const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  WIDGETS
// ============================================================

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

class _SubjectItem extends StatelessWidget {
  const _SubjectItem({
    required this.subject,
    required this.isCompact,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Subject subject;
  final bool isCompact;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textWhite : AppColors.textSecondary;
    final displayName = subject.icon != null ? '${subject.icon} ${subject.name}' : subject.name;

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
          color: subject.colorValue,
          shape: BoxShape.circle,
        ),
      ),
      title: isCompact
          ? null
          : Text(
              displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
      trailing: isCompact
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 👇 BOUTON TROIS POINTS
                if (!isCompact)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    color: isDark ? Colors.grey[800] : Colors.white,
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return isCompact
        ? Tooltip(
            message: subject.name,
            child: listTile,
          )
        : listTile;
  }
}

// ============================================================
//  BOUTON AJOUTER UNE MATIÈRE
// ============================================================

class _AddSubjectButton extends StatelessWidget {
  const _AddSubjectButton({
    required this.isCompact,
    required this.isDark,
    required this.onTap,
  });

  final bool isCompact;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textWhite : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        minLeadingWidth: isCompact ? 0 : 32,
        horizontalTitleGap: isCompact ? 0 : 12,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: 0,
        ),
        leading: Icon(
          Icons.add_circle_outline,
          color: AppColors.primary,
          size: isCompact ? 24 : 20,
        ),
        title: isCompact
            ? null
            : Text(
                'Ajouter une matière',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}