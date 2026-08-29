// frontend/lib/features/profile/widgets/profile_image_picker.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';

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
  File? _selectedImage;
  bool _isLoading = false;
  String? _uploadedImageUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Stack(
        children: [
          // Avatar
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
            child: _selectedImage == null && widget.currentImageUrl == null
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
          // Badge de modification
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

  // ✅ CORRECTION : Retourner DecorationImage directement
  DecorationImage? _getImageProvider() {
    if (_selectedImage != null) {
      return DecorationImage(
        image: FileImage(_selectedImage!),
        fit: BoxFit.cover,
      );
    }
    if (widget.currentImageUrl != null) {
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
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
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
                  _buildPickerOption(
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    subtitle: 'Choisir une photo existante',
                    onTap: () => _pickImage(ImageSource.gallery),
                    isDark: isDark,
                  ),
                  const Divider(),
                  _buildPickerOption(
                    icon: Icons.camera_alt,
                    label: 'Appareil photo',
                    subtitle: 'Prendre une nouvelle photo',
                    onTap: () => _pickImage(ImageSource.camera),
                    isDark: isDark,
                  ),
                  const Divider(),
                  if (_selectedImage != null || widget.currentImageUrl != null)
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

  // ✅ SOLUTION CORRIGÉE : Utiliser XFile directement
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      
      // ✅ Pour une seule image
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
        });

        // ✅ Uploader l'image
        await _uploadImage(pickedFile);
        
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur sélection image: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la sélection de l\'image'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ✅ Upload vers votre backend FastAPI
  Future<void> _uploadImage(XFile imageFile) async {
    try {
      // Lire les bytes du fichier
      final bytes = await imageFile.readAsBytes();
      
      // Créer le FormData
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      // Envoyer au backend
      final response = await widget.apiClient.post(
        '/auth/me/avatar',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final avatarUrl = data['avatar_url'];
        
        setState(() {
          _uploadedImageUrl = avatarUrl;
          _selectedImage = null;
        });
        
        // ✅ Notifier le parent
        widget.onImageSelected(avatarUrl);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Photo de profil mise à jour'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              //borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
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
      _selectedImage = null;
    });
    widget.onImageSelected(null);
  }
}