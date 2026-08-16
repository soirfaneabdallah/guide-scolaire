// frontend/lib/features/library/widgets/create_book_dialog.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../providers/library_provider.dart';
import '../../../core/constants/app_colors.dart';

class CreateBookDialog extends StatefulWidget {
  const CreateBookDialog({
    super.key,
    required this.provider,
  });

  final LibraryProvider provider;

  @override
  State<CreateBookDialog> createState() => _CreateBookDialogState();
}

class _CreateBookDialogState extends State<CreateBookDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  String? _selectedLevel;
  int? _selectedSubjectId;
  bool _isPublic = true;
  bool _isLoading = false;
  bool _isDragging = false;

  // Fichiers
  FilePickerResult? _pdfFile;
  FilePickerResult? _coverImage;
  String? _pdfFileName;
  String? _coverFileName;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<String> _levels = ['Collège', 'Lycée', 'Université'];
  final List<Map<String, dynamic>> _subjects = const [
    {'id': 1, 'name': 'Mathématiques', 'icon': '📐'},
    {'id': 2, 'name': 'Français', 'icon': '📖'},
    {'id': 3, 'name': 'Physique-Chimie', 'icon': '⚡'},
    {'id': 4, 'name': 'SVT', 'icon': '🧬'},
    {'id': 5, 'name': 'Histoire-Géographie', 'icon': '🏛️'},
    {'id': 6, 'name': 'Anglais', 'icon': '🗣️'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 24,
        child: Container(
          width: isMobile ? double.infinity : 640,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ============================================================
              //  EN-TÊTE
              // ============================================================
              _buildHeader(isDark, isMobile),
              const SizedBox(height: 16),

              // ============================================================
              //  CONTENU SCROLLABLE
              // ============================================================
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      _buildTextField(
                        controller: _titleController,
                        label: 'Titre du livre *',
                        icon: Icons.title,
                        isDark: isDark,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 12),

                      // Auteur
                      _buildTextField(
                        controller: _authorController,
                        label: 'Auteur *',
                        icon: Icons.person,
                        isDark: isDark,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 12),

                      // Description
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description *',
                        icon: Icons.description,
                        isDark: isDark,
                        isMobile: isMobile,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),

                      // Niveau
                      _buildDropdown(
                        value: _selectedLevel,
                        label: 'Niveau',
                        icon: Icons.school,
                        items: _levels.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedLevel = value);
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Matière
                      _buildDropdown(
                        value: _selectedSubjectId,
                        label: 'Matière',
                        icon: Icons.book,
                        items: _subjects.map((subject) {
                          return DropdownMenuItem(
                            value: subject['id'],
                            child: Text('${subject['icon']} ${subject['name']}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedSubjectId = value);
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Upload PDF
                      _buildFileUpload(
                        label: '📄 Fichier PDF *',
                        file: _pdfFile,
                        fileName: _pdfFileName,
                        onTap: _pickPDF,
                        isDark: isDark,
                        isOptional: false,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 12),

                      // Upload Couverture
                      _buildFileUpload(
                        label: '🖼️ Couverture (optionnelle)',
                        file: _coverImage,
                        fileName: _coverFileName,
                        onTap: _pickCover,
                        isDark: isDark,
                        isOptional: true,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 12),

                      // Public/Privé
                      _buildPublicToggle(isDark),
                    ],
                  ),
                ),
              ),

              // ============================================================
              //  ACTIONS
              // ============================================================
              _buildActions(isDark, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  HEADER
  // ============================================================

  Widget _buildHeader(bool isDark, bool isMobile) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Publier un livre',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                ),
              ),
              Text(
                'Partagez vos connaissances avec la communauté',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
      ],
    );
  }

  // ============================================================
  //  TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required bool isMobile,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? AppColors.textWhite : AppColors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : AppColors.background,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 12,
        ),
      ),
    );
  }

  // ============================================================
  //  DROPDOWN
  // ============================================================

  Widget _buildDropdown({
    required dynamic value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem> items,
    required ValueChanged onChanged,
    required bool isDark,
  }) {
    return DropdownButtonFormField(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : AppColors.background,
      ),
      items: items,
      onChanged: onChanged,
      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
      style: TextStyle(
        color: isDark ? AppColors.textWhite : AppColors.textPrimary,
        fontSize: 14,
      ),
    );
  }

  // ============================================================
  //  FILE UPLOAD
  // ============================================================

  Widget _buildFileUpload({
    required String label,
    required FilePickerResult? file,
    required String? fileName,
    required VoidCallback onTap,
    required bool isDark,
    required bool isOptional,
    required bool isMobile,
  }) {
    final hasFile = file != null;
    final isDragging = _isDragging;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: hasFile
              ? AppColors.success.withOpacity(0.05)
              : isDark
                  ? AppColors.darkBackground
                  : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile
                ? AppColors.success
                : isDragging
                    ? AppColors.primary
                    : isDark
                        ? AppColors.borderDark
                        : AppColors.border,
            width: isDragging ? 2 : 1,
          ),
          boxShadow: [
            if (isDragging)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 12,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.success.withOpacity(0.1)
                    : isDark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasFile ? Icons.check_circle : Icons.cloud_upload,
                color: hasFile ? AppColors.success : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile ? fileName! : (isOptional ? 'Cliquez pour sélectionner (optionnel)' : 'Cliquez pour sélectionner *'),
                    style: TextStyle(
                      fontSize: 12,
                      color: hasFile ? AppColors.success : AppColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  PUBLIC TOGGLE
  // ============================================================

  Widget _buildPublicToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isPublic ? Icons.public : Icons.lock,
            color: _isPublic ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPublic ? 'Public' : 'Privé',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                ),
                Text(
                  _isPublic
                      ? 'Tout le monde peut voir ce livre'
                      : 'Seulement vous pouvez voir ce livre',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) {
              setState(() => _isPublic = value);
            },
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  ACTIONS
  // ============================================================

  Widget _buildActions(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _isLoading ? 0 : 4,
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
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.publish, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Publier',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  SÉLECTION DES FICHIERS
  // ============================================================

  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _pdfFile = result;
          _pdfFileName = result.files.first.name;
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection du PDF');
    }
  }

  Future<void> _pickCover() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _coverImage = result;
          _coverFileName = result.files.first.name;
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection de la couverture');
    }
  }

  // ============================================================
  //  UPLOAD DES FICHIERS
  // ============================================================

  Future<String?> _uploadFile(FilePickerResult file, String type) async {
    try {
      final bytes = file.files.first.bytes;
      final fileName = file.files.first.name;
      if (bytes == null) return null;

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
        'type': type,
      });

      final response = await widget.provider.apiClient!.post(
        '/books/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['url'];
      }
      return null;
    } catch (e) {
      _showError('Erreur lors de l\'upload: $e');
      return null;
    }
  }

  // ============================================================
  //  CRÉATION DU LIVRE
  // ============================================================

  Future<void> _createBook() async {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      _showError('Veuillez entrer un titre');
      return;
    }
    if (_authorController.text.trim().isEmpty) {
      _showError('Veuillez entrer un auteur');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Veuillez entrer une description');
      return;
    }
    if (_pdfFile == null) {
      _showError('Veuillez sélectionner un fichier PDF');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String title = _titleController.text.trim();
      final String author = _authorController.text.trim();
      final String description = _descriptionController.text.trim();
      final String? level = _selectedLevel;
      final int? subjectId = _selectedSubjectId;
      final bool isPublic = _isPublic;

      String? coverUrl;
      if (_coverImage != null) {
        coverUrl = await _uploadFile(_coverImage!, 'cover');
      }

      String? pdfUrl = await _uploadFile(_pdfFile!, 'pdf');

      if (pdfUrl == null) {
        _showError('Erreur lors de l\'upload du fichier PDF');
        setState(() => _isLoading = false);
        return;
      }

      final success = await widget.provider.createBook(
        title: title,
        author: author,
        description: description,
        level: level,
        subjectId: subjectId,
        isPublic: isPublic,
        coverImage: coverUrl ?? _getDefaultCover(),
        fileUrl: pdfUrl,
      );

      if (success && context.mounted) {
        Navigator.pop(context);
        _showSuccess('✅ Livre publié avec succès !');
      } else if (context.mounted) {
        setState(() => _isLoading = false);
        _showError(widget.provider.error ?? 'Erreur lors de la publication');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  // ============================================================
  //  UTILITAIRES
  // ============================================================

  String _getDefaultCover() {
    return 'https://via.placeholder.com/400x600/4CAF50/FFFFFF?text=📚';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}