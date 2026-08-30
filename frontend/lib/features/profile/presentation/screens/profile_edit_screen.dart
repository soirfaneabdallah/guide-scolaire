// frontend/lib/features/profile/presentation/screens/profile_edit_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/environment.dart';
import '../../../auth/providers/auth_provider.dart';
import '../widgets/profile_image_picker.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _levelController = TextEditingController();
  final _schoolController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  
  // État
  File? _selectedAvatar;
  String? _currentAvatarUrl;
  bool _isLoading = false;
  bool _isAvatarUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _levelController.dispose();
    _schoolController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    
    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _levelController.text = user.level ?? '';
      _schoolController.text = user.school ?? '';
      _phoneController.text = user.phoneNumber ?? '';
      _bioController.text = user.bio ?? '';
      
      // ✅ Construire l'URL complète de l'avatar
      final avatarPath = user.avatarUrl;
      if (avatarPath != null && avatarPath.isNotEmpty) {
        _currentAvatarUrl = _buildFullUrl(avatarPath);
      }
    }
  }

  String _buildFullUrl(String path) {
    // Si le chemin commence déjà par http, le retourner tel quel
    if (path.startsWith('http')) return path;
    
    // Sinon, construire l'URL complète
    final baseUrl = EnvironmentConfig.baseUrl;
    // Supprimer le slash final du baseUrl si présent
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    // Ajouter un slash au début du path si nécessaire
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanBaseUrl$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final apiClient = Provider.of<ApiClient>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? AppColors.textWhite : AppColors.textPrimary,
        actions: [
          // ✅ Indicateur de sauvegarde
          if (_isLoading || _isAvatarUploading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
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
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ ProfileImagePicker amélioré avec caméra et crop
              ProfileImagePicker(
                currentImageUrl: _currentAvatarUrl,
                onImageSelected: (url) {
                  setState(() {
                    if (url != null) {
                      _currentAvatarUrl = _buildFullUrl(url);
                    } else {
                      _currentAvatarUrl = null;
                      _selectedAvatar = null;
                    }
                  });
                },
                apiClient: apiClient,
                radius: isMobile ? 50 : 60,
              ),
              
              const SizedBox(height: 8),
              
              // ✅ Message d'aide
              Center(
                child: Text(
                  'Appuyez sur la caméra pour changer votre photo',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // ========== FORMULAIRE ==========
              
              // Prénom
              _buildTextField(
                controller: _firstNameController,
                label: 'Prénom *',
                icon: Icons.person_outline,
                isDark: isDark,
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le prénom est requis';
                  }
                  if (value.trim().length < 2) {
                    return 'Minimum 2 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nom
              _buildTextField(
                controller: _lastNameController,
                label: 'Nom *',
                icon: Icons.person_outline,
                isDark: isDark,
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  if (value.trim().length < 2) {
                    return 'Minimum 2 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Niveau (Dropdown)
              _buildDropdownField(
                value: _levelController.text,
                label: 'Niveau scolaire',
                icon: Icons.school_outlined,
                items: const [
                  '6ème', '5ème', '4ème', '3ème',
                  'Seconde', 'Première', 'Terminale',
                  'Licence 1', 'Licence 2', 'Licence 3',
                  'Master 1', 'Master 2',
                ],
                onChanged: (value) {
                  setState(() {
                    _levelController.text = value ?? '';
                  });
                },
                isDark: isDark,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // École
              _buildTextField(
                controller: _schoolController,
                label: 'École / Établissement',
                icon: Icons.business_outlined,
                isDark: isDark,
                enabled: !_isLoading,
                hintText: 'Ex: Lycée Jean-Jacques Rousseau',
              ),
              const SizedBox(height: 16),

              // Téléphone
              _buildTextField(
                controller: _phoneController,
                label: 'Téléphone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                isDark: isDark,
                enabled: !_isLoading,
                hintText: 'Ex: 06 12 34 56 78',
              ),
              const SizedBox(height: 16),

              // Bio
              _buildTextField(
                controller: _bioController,
                label: 'Biographie',
                icon: Icons.description_outlined,
                maxLines: 4,
                isDark: isDark,
                enabled: !_isLoading,
                hintText: 'Parlez-nous un peu de vous...',
              ),
              const SizedBox(height: 32),

              // ========== BOUTONS ==========
              _buildButtons(isDark),
              
              const SizedBox(height: 16),
              
              // ✅ Bouton de suppression de compte (optionnel)
              TextButton(
                onPressed: _isLoading ? null : _showDeleteAccountDialog,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: const Text('Supprimer mon compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== WIDGETS ==========

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : AppColors.background,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 12,
        ),
      ),
      style: TextStyle(
        color: isDark ? AppColors.textWhite : AppColors.textPrimary,
        fontSize: 15,
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value.isNotEmpty ? value : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
        icon: Icon(
          Icons.arrow_drop_down, 
          color: isDark ? Colors.white : Colors.black,
        ),
        style: TextStyle(
          color: isDark ? AppColors.textWhite : AppColors.textPrimary,
          fontSize: 15,
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
        isExpanded: true,
      ),
    );
  }

  Widget _buildButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
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
        ),
      ],
    );
  }

  // ========== ACTIONS ==========

  Future<void> _saveProfile() async {
    // ✅ Valider le formulaire
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // ✅ 1. Upload de l'avatar si sélectionné (le ProfileImagePicker l'a déjà fait)
      // ✅ Le ProfileImagePicker gère déjà l'upload via son callback
      
      // ✅ 2. Mise à jour du profil
      final success = await authProvider.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        level: _levelController.text.trim().isNotEmpty ? _levelController.text.trim() : null,
        school: _schoolController.text.trim().isNotEmpty ? _schoolController.text.trim() : null,
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        // L'avatar est déjà mis à jour via le ProfileImagePicker
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        _showSnackBar(
          '✅ Profil mis à jour avec succès',
          AppColors.success,
        );
        // ✅ Recharger les données utilisateur
        await authProvider.loadUserProfile();
        Navigator.pop(context);
      } else {
        _showSnackBar(
          authProvider.error ?? '❌ Erreur lors de la mise à jour',
          AppColors.error,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
        '❌ Erreur: $e',
        AppColors.error,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront supprimées.\n'
          'Êtes-vous sûr de vouloir continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
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

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.deleteAccount();
      
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      if (success) {
        _showSnackBar(
          '✅ Compte supprimé avec succès',
          AppColors.success,
        );
        // Rediriger vers la page de login
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      } else {
        _showSnackBar(
          authProvider.error ?? '❌ Erreur lors de la suppression',
          AppColors.error,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
        '❌ Erreur: $e',
        AppColors.error,
      );
    }
  }
}