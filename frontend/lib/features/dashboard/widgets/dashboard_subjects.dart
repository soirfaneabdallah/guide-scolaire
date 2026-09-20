// frontend/lib/features/dashboard/widgets/dashboard_subjects.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../core/constants/app_colors.dart';
import 'create_subject_dialog.dart';

class DashboardSubjects extends StatefulWidget {
  const DashboardSubjects({
    super.key,
    this.isMobile = false,
    this.onSubjectSelected,
  });

  final bool isMobile;
  final Function(Subject)? onSubjectSelected;

  @override
  State<DashboardSubjects> createState() => _DashboardSubjectsState();
}

class _DashboardSubjectsState extends State<DashboardSubjects>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = dashboardProvider.subjects;
    final isLoading = dashboardProvider.isLoading;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(dashboardProvider, isDark),
          const SizedBox(height: 16),
          if (isLoading && subjects.isEmpty)
            _buildLoadingState()
          else if (subjects.isEmpty)
            _buildEmptyState(dashboardProvider, isDark)
          else
            _buildSubjectsGrid(subjects, dashboardProvider, isDark),
        ],
      ),
    );
  }

  // ============================================================
  //  HEADER ÉPURÉ
  // ============================================================

  Widget _buildHeader(DashboardProvider provider, bool isDark) {
    return Row(
      children: [
        Text(
          'Mes matières',
          style: TextStyle(
            fontSize: widget.isMobile ? 18 : 20,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textWhite : AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        if (!provider.isLoading)
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            color: isDark ? Colors.white : AppColors.textPrimary,
            onPressed: () => _showCreateSubjectDialog(context),
            tooltip: 'Ajouter une matière',
          ),
      ],
    );
  }

  // ============================================================
  //  ÉTATS
  // ============================================================

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Chargement des matières...',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(DashboardProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune matière pour le moment',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textWhite : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoute ta première matière pour commencer',
            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _showCreateSubjectDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter une matière'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  GRILLE DE MATIÈRES
  // ============================================================

  Widget _buildSubjectsGrid(
    List<Subject> subjects,
    DashboardProvider provider,
    bool isDark,
  ) {
    final crossAxisCount = widget.isMobile
        ? 2
        : MediaQuery.of(context).size.width > 900
            ? 4
            : MediaQuery.of(context).size.width > 600
                ? 3
                : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: widget.isMobile ? 2.5 : 2.8,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return _SubjectCard(
          subject: subject,
          isDark: isDark,
          onTap: () {
            // ✅ Sélectionner la matière
            provider.selectSubject(subject);

            // ✅ Notifier le parent si un callback est fourni
            if (widget.onSubjectSelected != null) {
              widget.onSubjectSelected!(subject);
            }
          },
          onDelete: () => _confirmDeleteSubject(context, provider, subject),
          onEdit: () => _showEditSubjectDialog(context, provider, subject),
          isMobile: widget.isMobile,
        );
      },
    );
  }

  // ============================================================
  //  DIALOGUES
  // ============================================================

  void _showCreateSubjectDialog(BuildContext context) {
    final provider = context.read<DashboardProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        child: CreateSubjectDialog(
          provider: provider,
          isDark: isDark,
        ),
      ),
    );
  }

  void _showEditSubjectDialog(
    BuildContext context,
    DashboardProvider provider,
    Subject subject,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: _EditSubjectDialog(
          provider: provider,
          subject: subject,
          isDark: isDark,
        ),
      ),
    );
  }

  void _confirmDeleteSubject(
    BuildContext context,
    DashboardProvider provider,
    Subject subject,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          'Êtes-vous sûr de vouloir supprimer "${subject.displayName}" ?',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textWhite : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteSubject(subject.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Matière supprimée'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      provider.error ?? 'Erreur lors de la suppression',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  CARTE DE MATIÈRE ÉPURÉE
// ============================================================

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    this.isMobile = false,
  });

  final Subject subject;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Nom de la matière (juste le texte)
              Expanded(
                child: Text(
                  subject.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                ),
              ),

              // Menu contextuel (éditer / supprimer)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                color: isDark ? AppColors.surfaceDark : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.border,
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
                          'Modifier',
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
    );
  }
}

// ============================================================
//  DIALOGUE D'ÉDITION ÉPURÉ
// ============================================================

class _EditSubjectDialog extends StatefulWidget {
  const _EditSubjectDialog({
    required this.provider,
    required this.subject,
    required this.isDark,
  });

  final DashboardProvider provider;
  final Subject subject;
  final bool isDark;

  @override
  State<_EditSubjectDialog> createState() => _EditSubjectDialogState();
}

class _EditSubjectDialogState extends State<_EditSubjectDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.subject.displayName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              color: widget.isDark
                  ? AppColors.textWhite
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            style: TextStyle(
              fontSize: 15,
              color: widget.isDark
                  ? AppColors.textWhite
                  : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Nom',
              hintText: widget.subject.name,
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
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _isLoading ? null : _updateSubject,
                child: _isLoading
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
    );
  }

  Future<void> _updateSubject() async {
    setState(() => _isLoading = true);

    final success = await widget.provider.updateSubject(
      subjectId: widget.subject.id,
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : null,
    );

    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Matière modifiée'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (context.mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.provider.error ?? 'Erreur'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}