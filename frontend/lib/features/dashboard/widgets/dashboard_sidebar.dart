// frontend/lib/features/dashboard/presentation/widgets/dashboard_sidebar.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/dashboard_provider.dart';
import 'create_subject_dialog.dart';
import 'sidebar_profile.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
    this.isCompact = false,
  });

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = provider.subjects;

    final isMobile = MediaQuery.of(context).size.width < 600;
    final compact = isCompact || isMobile;

    return Container(
      width: compact ? 200 : 260,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildLogo(isDark, compact),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.divider,
          ),
          _buildFixedMenu(isDark, provider, context, compact),
          Expanded(
            child: _buildSubjectsList(isDark, provider, subjects, context, compact),
          ),
          _buildFixedBottomMenu(isDark, provider, compact),
          SidebarProfile(isCompact: compact),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isDark, bool compact) {
    final size = compact ? 20.0 : 26.0;
    final fontSize = compact ? 14.0 : 15.0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 14 : 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/logo.svg',
            width: size,
            height: size,
            colorFilter: ColorFilter.mode(
              isDark ? Colors.white : AppColors.textPrimary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'E-learningAI',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: isDark ? AppColors.textWhite : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedMenu(
    bool isDark,
    DashboardProvider provider,
    BuildContext context,
    bool compact,
  ) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _SidebarItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: 'Accueil',
          isCompact: compact,
          isDark: isDark,
          isSelected: provider.selectedIndex == 0,
          onTap: () => provider.selectTab(0),
        ),
        const SizedBox(height: 8),
        _AddSubjectButton(
          isCompact: compact,
          isDark: isDark,
          onTap: () {
            _showAddSubjectDialog(context, provider);
          },
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                'MATIÈRES',
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              if (provider.isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsList(
    bool isDark,
    DashboardProvider provider,
    List<Subject> subjects,
    BuildContext context,
    bool compact,
  ) {
    if (provider.isLoading && subjects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    if (subjects.isEmpty) {
      return compact
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Aucune matière',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            );
    }

    final ScrollController scrollController = ScrollController();

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: false,
      radius: const Radius.circular(8),
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          return _SubjectItem(
            subject: subject,
            isCompact: compact,
            isDark: isDark,
            isSelected: provider.selectedSubjectSlug == subject.slug &&
                provider.selectedIndex == 0,
            onTap: () {
              provider.selectSubject(subject); // ✅ Accepte un Subject
            },
            onEdit: () {
              _showEditSubjectDialog(context, provider, subject);
            },
            onDelete: () {
              _showDeleteSubjectDialog(context, provider, subject);
            },
          );
        },
      ),
    );
  }

  Widget _buildFixedBottomMenu(
    bool isDark,
    DashboardProvider provider,
    bool compact,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        const SizedBox(height: 4),
        _SidebarItem(
          icon: Icons.edit_note_outlined,
          selectedIcon: Icons.edit_note_rounded,
          label: 'Exercices',
          isCompact: compact,
          isDark: isDark,
          isSelected: provider.selectedIndex == 2,
          onTap: () => provider.selectTab(2),
        ),
        _SidebarItem(
          icon: Icons.draw_outlined,
          selectedIcon: Icons.draw_rounded,
          label: 'Cahier',
          isCompact: compact,
          isDark: isDark,
          isSelected: provider.selectedIndex == 3,
          onTap: () => provider.selectTab(3),
        ),
        _SidebarItem(
          icon: Icons.library_books_outlined,
          selectedIcon: Icons.library_books_rounded,
          label: 'Bibliothèque',
          isCompact: compact,
          isDark: isDark,
          isSelected: provider.selectedIndex == 4,
          onTap: () => provider.selectTab(4),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ============================================================
  // DIALOGUES
  // ============================================================

  void _showAddSubjectDialog(BuildContext context, DashboardProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CreateSubjectDialog(
        provider: provider,
        isDark: isDark,
      ),
    );
  }

  // ✅ Dialog d'édition épuré (juste le nom)
  void _showEditSubjectDialog(
    BuildContext context,
    DashboardProvider provider,
    Subject subject,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController nameController =
        TextEditingController(text: subject.name);
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Renommer la matière',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    hintText: subject.name,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (nameController.text.trim().isEmpty) {
                                return;
                              }
                              setState(() => isLoading = true);
                              final success = await provider.updateSubject(
                                subjectId: subject.id,
                                name: nameController.text.trim(),
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Matière modifiée'
                                        : 'Erreur : ${provider.error ?? "Inconnue"}',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Dialog de suppression épuré
  void _showDeleteSubjectDialog(
    BuildContext context,
    DashboardProvider provider,
    Subject subject,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Supprimer la matière',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textWhite : AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer "${subject.name}" ?',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textWhite : AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      final success = await provider.deleteSubject(subject.id);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Matière supprimée'
                                : 'Erreur : ${provider.error ?? "Inconnue"}',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Supprimer',
                      style: TextStyle(color: AppColors.error),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  WIDGETS
// ============================================================

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isCompact,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
    this.selectedIcon,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isCompact;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDark ? AppColors.textWhite : AppColors.textSecondary;
    final selectedColor =
        widget.isDark ? Colors.white : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
      child: Material(
        color: widget.isSelected
            ? (widget.isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: widget.isDark
              ? Colors.white.withOpacity(0.045)
              : Colors.black.withOpacity(0.035),
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 10 : 12,
              vertical: 10,
            ),
            child: Row(
              children: [
                Icon(
                  widget.isSelected
                      ? (widget.selectedIcon ?? widget.icon)
                      : widget.icon,
                  color: widget.isSelected ? selectedColor : textColor,
                  size: 20,
                ),
                SizedBox(width: widget.isCompact ? 10 : 14),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: widget.isCompact ? 12 : 14,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.isSelected ? selectedColor : textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Item de matière épuré (sans emoji ni couleur)
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
    final textColor =
        isDark ? AppColors.textWhite : AppColors.textSecondary;
    final selectedColor = isDark ? Colors.white : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: isSelected
            ? (isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: isDark
              ? Colors.white.withOpacity(0.045)
              : Colors.black.withOpacity(0.035),
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 12,
              vertical: 8,
            ),
            child: Row(
              children: [
                // ✅ Juste le nom, pas de point coloré ni d'emoji
                Expanded(
                  child: Text(
                    subject.displayName,
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? selectedColor : textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isCompact && isSelected)
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                if (!isCompact)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: textColor.withOpacity(0.6),
                    ),
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    tooltip: 'Options',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color:
                            isDark ? AppColors.borderDark : AppColors.border,
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: isDark
                                  ? AppColors.textWhite
                                  : AppColors.textPrimary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Renommer',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.textWhite
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Supprimer',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Bouton d'ajout épuré (sans dégradé)
class _AddSubjectButton extends StatefulWidget {
  const _AddSubjectButton({
    required this.isCompact,
    required this.isDark,
    required this.onTap,
  });

  final bool isCompact;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_AddSubjectButton> createState() => _AddSubjectButtonState();
}

class _AddSubjectButtonState extends State<_AddSubjectButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final compact = widget.isCompact;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: 2,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Material(
          color: _hovering
              ? (widget.isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 8 : 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add,
                    size: compact ? 16 : 18,
                    color:
                        widget.isDark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ajouter une matière',
                      style: TextStyle(
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w500,
                        color: widget.isDark
                            ? AppColors.textWhite
                            : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}