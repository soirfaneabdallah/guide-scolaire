// frontend/lib/features/dashboard/widgets/dashboard_subjects.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../core/constants/app_colors.dart';
import 'create_subject_dialog.dart'; // ✅ Le nouveau dialogue

class DashboardSubjects extends StatefulWidget {
  const DashboardSubjects({
    super.key,
    this.isMobile = false,
  });

  final bool isMobile;

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

  Widget _buildHeader(DashboardProvider provider, bool isDark) {
    return Row(
      children: [
        Text(
          '📚 Mes matières',
          style: TextStyle(
            fontSize: widget.isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textWhite : AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (!provider.isLoading)
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 24),
            color: AppColors.primary,
            onPressed: () => _showCreateSubjectDialog(context),
            tooltip: 'Ajouter une matière',
          ),
      ],
    );
  }

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
            size: 64,
            color: AppColors.textTertiary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune matière pour le moment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textWhite : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoute ta première matière pour commencer',
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateSubjectDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une matière'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsGrid(
    List<Subject> subjects,
    DashboardProvider provider,
    bool isDark,
  ) {
    final crossAxisCount = widget.isMobile
        ? 3
        : MediaQuery.of(context).size.width > 600 ? 4 : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: widget.isMobile ? 0.9 : 1,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return _SubjectCard(
          subject: subject,
          isDark: isDark,
          onTap: () {},
          onDelete: () => _confirmDeleteSubject(context, provider, subject),
          onEdit: () => _showEditSubjectDialog(context, provider, subject),
          isMobile: widget.isMobile,
        );
      },
    );
  }

  // ✅ Méthode pour ouvrir le dialogue
  void _showCreateSubjectDialog(BuildContext context) {
    final provider = context.read<DashboardProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
    final isDefault = subject.isDefault;

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
            color: isDark ? AppColors.textWhite : AppColors.textPrimary,
          ),
        ),
        content: Text(
          isDefault
              ? '⚠️ Cette matière est une matière par défaut. Elle sera retirée de votre liste mais restera disponible pour les autres utilisateurs.'
              : 'Êtes-vous sûr de vouloir supprimer "${subject.name}" ?',
          style: TextStyle(
            color: isDark ? AppColors.textWhite : AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteSubject(subject.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Matière supprimée avec succès'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'Erreur lors de la suppression'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  WIDGET DE CARTE DE MATIÈRE
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
    final color = subject.color != null
        ? Color(int.parse(subject.color!.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    final icon = subject.icon ?? _getDefaultIcon(subject.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subject.displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                    ),
                  ),
                  if (subject.isDefault)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '📌',
                        style: TextStyle(fontSize: 10, color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!subject.isActive)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Inactif',
                    style: TextStyle(fontSize: 8, color: AppColors.error),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getDefaultIcon(String name) {
    const defaultIcons = {
      'math': '📐',
      'français': '📖',
      'physique': '⚡',
      'svt': '🧬',
      'histoire': '🏛️',
      'anglais': '🗣️',
      'chimie': '🧪',
      'philosophie': '💭',
      'espagnol': '🇪🇸',
      'allemand': '🇩🇪',
      'italien': '🇮🇹',
      'latin': '🏛️',
      'sport': '⚽',
      'musique': '🎵',
      'art': '🎨',
      'informatique': '💻',
      'programmation': '💻',
      'économie': '📊',
      'gestion': '📋',
    };

    final lowerName = name.toLowerCase();
    for (final entry in defaultIcons.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }
    return '📚';
  }
}

// ============================================================
//  DIALOGUE D'ÉDITION DE MATIÈRE
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
  final TextEditingController _iconController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.subject.displayName;
    _iconController.text = widget.subject.icon ?? '';
    _colorController.text = widget.subject.color ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    _colorController.dispose();
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
            'Modifier la matière',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? AppColors.textWhite : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nom personnalisé',
              hintText: widget.subject.name,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.school_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _iconController,
                  decoration: InputDecoration(
                    labelText: 'Icône (emoji)',
                    hintText: widget.subject.icon ?? '📚',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.emoji_emotions_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _colorController,
                  decoration: InputDecoration(
                    labelText: 'Couleur (hex)',
                    hintText: widget.subject.color ?? '#0066FF',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.color_lens_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateSubject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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
      icon: _iconController.text.trim().isNotEmpty
          ? _iconController.text.trim()
          : null,
      color: _colorController.text.trim().isNotEmpty
          ? _colorController.text.trim()
          : null,
    );

    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Matière modifiée avec succès !')),
      );
    } else if (context.mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.provider.error ?? 'Erreur lors de la modification'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}