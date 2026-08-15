// frontend/lib/features/dashboard/widgets/create_subject_dialog.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/color_picker.dart';
import '../../../core/widgets/icon_picker.dart';
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
  String _selectedIcon = '📚';
  String _selectedColor = '#4CAF50';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Rendre responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth * 0.92 : 480.0;
    final padding = isMobile ? 16.0 : 24.0;

    return Dialog(
      backgroundColor: widget.isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
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
              // En-tête
              Row(
                children: [
                  Container(
                    width: isMobile ? 40 : 48,
                    height: isMobile ? 40 : 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: isMobile ? 22 : 28,
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Text(
                      'Nouvelle matière',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark
                            ? AppColors.textWhite
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 16 : 20),

              // Champ nom
              TextField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Nom de la matière *',
                  hintText: 'ex: Programmation Dart',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                    borderSide: BorderSide(
                      color: widget.isDark ? AppColors.borderDark : AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                    borderSide: BorderSide(
                      color: widget.isDark ? AppColors.borderDark : AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.school_outlined),
                  filled: true,
                  fillColor: widget.isDark
                      ? AppColors.surfaceDark
                      : AppColors.surface,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 12 : 16,
                  ),
                ),
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: widget.isDark ? AppColors.textWhite : AppColors.textPrimary,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),

              // Sélecteur d'icône
              IconPicker(
                selectedIcon: _selectedIcon,
                onIconSelected: (icon) {
                  setState(() => _selectedIcon = icon);
                },
                itemSize: isMobile ? 36 : 44,
                showSearch: !isMobile,
              ),
              SizedBox(height: isMobile ? 12 : 16),

              // Sélecteur de couleur
              ColorPicker(
                selectedColor: _selectedColor,
                onColorSelected: (color) {
                  setState(() => _selectedColor = color);
                },
                itemSize: isMobile ? 30 : 36,
              ),
              SizedBox(height: isMobile ? 16 : 20),

              // Aperçu
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                  border: Border.all(
                    color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')))
                        .withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: isMobile ? 36 : 40,
                      height: isMobile ? 36 : 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')))
                            .withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _selectedIcon,
                          style: TextStyle(fontSize: isMobile ? 18 : 20),
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 10 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isEmpty
                                ? 'Nom de la matière'
                                : _nameController.text,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? AppColors.textWhite
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Aperçu de la matière',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                        fontSize: isMobile ? 14 : 15,
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 4 : 8),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createSubject,
                    icon: _isLoading
                        ? SizedBox(
                            width: isMobile ? 16 : 20,
                            height: isMobile ? 16 : 20,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.add, size: isMobile ? 16 : 18),
                    label: Text(
                      _isLoading ? 'Création...' : 'Créer',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: isMobile ? 10 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                      ),
                      elevation: 0,
                      minimumSize: isMobile
                          ? const Size(80, 40)
                          : const Size(100, 48),
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

  Future<void> _createSubject() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un nom'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.provider.createSubject(
      name: name,
      icon: _selectedIcon,
      color: _selectedColor,
    );

    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Matière créée avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (context.mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.provider.error ?? '❌ Erreur lors de la création'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}