// frontend/lib/features/dashboard/widgets/create_subject_dialog.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/dashboard_provider.dart';

class CreateSubjectDialog extends StatefulWidget {
  const CreateSubjectDialog({
    super.key,
    required this.provider,
    required this.isDark,
  });

  final DashboardProvider provider;
  final bool isDark;

  @override
  State<CreateSubjectDialog> createState() => _CreateSubjectDialogState();
}

class _CreateSubjectDialogState extends State<CreateSubjectDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth * 0.92 : 440.0;
    final padding = isMobile ? 20.0 : 24.0;

    return Dialog(
      backgroundColor:
          widget.isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: EdgeInsets.all(padding),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================================
              // TITRE
              // ============================================================
              Text(
                'Nouvelle matière',
                style: TextStyle(
                  fontSize: isMobile ? 17 : 18,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? AppColors.textWhite
                      : AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ajoute une matière à ton espace de travail',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 24),

              // ============================================================
              // CHAMP NOM
              // ============================================================
              TextField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _isLoading ? null : _createSubject(),
                decoration: InputDecoration(
                  labelText: 'Nom',
                  hintText: 'ex : Programmation',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: widget.isDark
                      ? AppColors.textWhite
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // ============================================================
              // ACTIONS
              // ============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isLoading ? null : _createSubject,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Créer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CRÉATION DE LA MATIÈRE
  // ============================================================

  Future<void> _createSubject() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un nom'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // ✅ Seuls le nom est requis désormais
    final success = await widget.provider.createSubject(
      name: name,
    );

    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Matière créée'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (context.mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.provider.error ?? 'Erreur lors de la création',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}