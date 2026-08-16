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
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
      ),
      child: Column(
        children: [
          _buildLogo(isDark, compact),
          const Divider(height: 1, color: AppColors.divider),
          _buildFixedMenu(isDark, provider, context, compact),
          Expanded(
            child: _buildSubjectsList(isDark, provider, subjects, context, compact),
          ),
          _buildFixedBottomMenu(isDark, provider, compact),
          // ------------------------------------------------------
          // Boîte profil : widget à part (sidebar_profile.dart),
          // toujours rendue ici, sans "if (!compact)" ni condition
          // de largeur -- seul son style interne s'adapte via
          // isCompact, jamais sa présence.
          // ------------------------------------------------------
          SidebarProfile(isCompact: compact),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isDark, bool compact) {
    final size = compact ? 28.0 : 40.0;
    final fontSize = compact ? 14.0 : 16.0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 14 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/logo.svg',
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(
              AppColors.primary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'E-learningAI',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
              color: isDark ? AppColors.textWhite : AppColors.primary,
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
        const SizedBox(height: 4),
        _SidebarItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: 'Accueil',
          isCompact: compact,
          isDark: isDark,
          isSelected: provider.selectedIndex == 0,
          onTap: () => provider.selectTab(0),
        ),
        const SizedBox(height: 10),
        _AddSubjectButton(
          isCompact: compact,
          isDark: isDark,
          onTap: () {
            _showAddSubjectDialog(context, provider);
          },
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                'MATIÈRES',
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w700,
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
              const SizedBox(width: 8),
              if (provider.isLoading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary.withOpacity(0.6),
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
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
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
              child: Row(
                children: [
                  Icon(Icons.inbox_outlined, size: 15, color: AppColors.textTertiary),
                  const SizedBox(width: 8),
                  Text(
                    'Aucune matière',
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
            );
    }

    return Scrollbar(
      thumbVisibility: false,
      radius: const Radius.circular(8),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          return _SubjectItem(
            subject: subject,
            isCompact: compact,
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
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
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

  void _showEditSubjectDialog(BuildContext context, DashboardProvider provider, Subject subject) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController nameController = TextEditingController(text: subject.name);
    final TextEditingController iconController = TextEditingController(text: subject.icon ?? '');
    final TextEditingController colorController = TextEditingController(text: subject.color ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.edit, color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Modifier la matière',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom de la matière *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.school_outlined),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
                  ),
                  style: TextStyle(
                    color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '😊 Icône',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: iconController,
                  decoration: InputDecoration(
                    hintText: 'Entrez un emoji (ex: 📚)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '🎨 Couleur',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: colorController,
                  decoration: InputDecoration(
                    hintText: 'Entrez une couleur hex (ex: #4CAF50)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        'Annuler',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez entrer un nom'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        setState(() => isLoading = true);
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
                              success ? '✅ Matière modifiée avec succès' : '❌ ${provider.error ?? "Erreur"}',
                            ),
                            backgroundColor: success ? AppColors.success : AppColors.error,
                          ),
                        );
                      },
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: Text(isLoading ? 'Enregistrement...' : 'Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
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

  void _showDeleteSubjectDialog(BuildContext context, DashboardProvider provider, Subject subject) {
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
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Supprimer',
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voulez-vous vraiment supprimer la matière',
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '"${subject.name}" ?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subject.isDefault
                            ? 'Cette matière est une matière par défaut. Elle sera retirée de votre liste mais restera disponible pour les autres utilisateurs.'
                            : 'Cette action est irréversible.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.error.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setState(() => isLoading = true);
                final success = await provider.deleteSubject(subject.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? '✅ Matière supprimée avec succès' : '❌ ${provider.error ?? "Erreur"}',
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Supprimer'),
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
    final textColor = widget.isDark ? AppColors.textWhite : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
      child: Material(
        color: widget.isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
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
                  widget.isSelected ? (widget.selectedIcon ?? widget.icon) : widget.icon,
                  color: widget.isSelected ? AppColors.primary : textColor,
                  size: 20,
                ),
                SizedBox(width: widget.isCompact ? 10 : 14),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: widget.isCompact ? 12 : 14,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: widget.isSelected ? AppColors.primary : textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isSelected)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: isDark ? Colors.white.withOpacity(0.045) : Colors.black.withOpacity(0.035),
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 12,
              vertical: 8,
            ),
            child: Row(
              children: [
                Container(
                  width: isCompact ? 6 : 8,
                  height: isCompact ? 6 : 8,
                  decoration: BoxDecoration(
                    color: subject.colorValue,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isCompact ? 10 : 14),
                Expanded(
                  child: Tooltip(
                    message: displayName,
                    waitDuration: const Duration(milliseconds: 500),
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.primary : textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (!isCompact)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18, color: textColor.withOpacity(0.7)),
                    color: isDark ? Colors.grey[800] : Colors.white,
                    tooltip: 'Options',
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
          ),
        ),
      ),
    );
  }
}

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
    final horizontalPadding = compact ? 8.0 : 12.0;
    final verticalPadding = compact ? 8.0 : 10.0;
    final iconSize = compact ? 16.0 : 18.0;
    final fontSize = compact ? 12.0 : 14.0;
    final arrowSize = compact ? 12.0 : 14.0;
    final boxHeight = compact ? 24.0 : 28.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedScale(
          scale: _hovering ? 1.015 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(10),
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                  vertical: verticalPadding,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(_hovering ? 0.35 : 0.25),
                      blurRadius: _hovering ? (compact ? 12 : 16) : (compact ? 8 : 12),
                      offset: const Offset(0, 3),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: boxHeight,
                      height: boxHeight,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ajouter une matière',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: compact ? 20 : 24,
                      height: compact ? 20 : 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: arrowSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}