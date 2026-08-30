// frontend/lib/features/profile/widgets/profile_image_picker.dart

import 'dart:io' show File, Directory; // ✅ Import conditionnel
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:universal_platform/universal_platform.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import 'dart:typed_data'; // ✅ Pour les bytes sur Web

class ProfileImagePicker extends StatefulWidget {
  const ProfileImagePicker({
    super.key,
    required this.currentImageUrl,
    required this.onImageSelected,
    required this.apiClient,
    this.radius = 60,
  });

  final String? currentImageUrl;
  final Function(String?) onImageSelected;
  final ApiClient apiClient;
  final double radius;

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  // ✅ Utiliser Uint8List pour stocker l'image (compatible Web)
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath; // Pour le nom du fichier
  bool _isLoading = false;
  String? _uploadedImageUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Stack(
        children: [
          Container(
            width: widget.radius * 2,
            height: widget.radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              image: _getImageProvider(),
            ),
            child: _selectedImageBytes == null && widget.currentImageUrl == null
                ? Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.radius * 0.6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  width: 3,
                ),
              ),
              child: IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                onPressed: _isLoading ? null : _showImagePicker,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DecorationImage? _getImageProvider() {
    if (_selectedImageBytes != null) {
      return DecorationImage(
        image: MemoryImage(_selectedImageBytes!),
        fit: BoxFit.cover,
      );
    }
    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(widget.currentImageUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  void _showImagePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Changer la photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // ✅ CAMÉRA (disponible sur mobile uniquement)
                  if (!UniversalPlatform.isWeb)
                    _buildPickerOption(
                      icon: Icons.camera_alt,
                      label: 'Appareil photo',
                      subtitle: 'Prendre une nouvelle photo',
                      onTap: () => _pickImage(ImageSource.camera),
                      isDark: isDark,
                    ),
                  
                  if (!UniversalPlatform.isWeb) const Divider(),
                  
                  // ✅ GALERIE (disponible partout)
                  _buildPickerOption(
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    subtitle: 'Choisir une photo existante',
                    onTap: () => _pickImage(ImageSource.gallery),
                    isDark: isDark,
                  ),
                  const Divider(),
                  
                  if (_selectedImageBytes != null || widget.currentImageUrl != null)
                    _buildPickerOption(
                      icon: Icons.delete_outline,
                      label: 'Supprimer la photo',
                      subtitle: 'Utiliser la photo par défaut',
                      onTap: _removeImage,
                      isDark: isDark,
                      isDestructive: true,
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.primary,
          size: 24,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? AppColors.error : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  // ✅ Méthode unifiée pour prendre/choisir une image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() => _isLoading = true);
        
        // ✅ Lire les bytes (fonctionne partout)
        final bytes = await pickedFile.readAsBytes();
        final fileName = pickedFile.name;
        
        // ✅ Uploader directement
        await _uploadImage(bytes, fileName);
        
        if (mounted) {
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImagePath = fileName;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur sélection image: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur lors de la sélection de l\'image');
      }
    }
  }

  // ✅ Upload avec Uint8List (compatible Web)
  Future<void> _uploadImage(Uint8List bytes, String fileName) async {
    try {
      // Créer le FormData avec les bytes
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}_$fileName',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      final response = await widget.apiClient.post(
        '/auth/me/avatar',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final avatarUrl = data['avatar_url'];
        
        // ✅ Notifier le parent
        widget.onImageSelected(avatarUrl);
        
        _showSuccess('✅ Photo de profil mise à jour');
      } else {
        throw Exception('Erreur lors de l\'upload');
      }
    } catch (e) {
      print('❌ Erreur upload: $e');
      rethrow;
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImagePath = null;
    });
    widget.onImageSelected(null);
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}