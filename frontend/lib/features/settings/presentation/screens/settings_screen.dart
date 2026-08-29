// frontend/lib/features/settings/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final settings = Provider.of<SettingsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? AppColors.textWhite : AppColors.textPrimary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => _showResetDialog(context),
            child: const Text('Réinitialiser'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
          ),
        ],
      ),
      body: settings.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                children: [
                  _buildProfileSection(isDark, auth),
                  const SizedBox(height: 24),
                  _buildAppearanceSection(isDark, settings),
                  const SizedBox(height: 24),
                  _buildNotificationsSection(isDark, settings),
                  const SizedBox(height: 24),
                  _buildPreferencesSection(isDark, settings),
                  const SizedBox(height: 24),
                  _buildAccountSection(isDark, auth),
                  const SizedBox(height: 24),
                  _buildAboutSection(isDark),
                ],
              ),
            ),
    );
  }

  // ============================================================
  //  SECTION PROFIL
  // ============================================================

  Widget _buildProfileSection(bool isDark, AuthProvider auth) {
    final userName = auth.userName ?? 'Élève';
    final userEmail = auth.userEmail ?? 'email@exemple.com';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Profil',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            title: Text(
              userName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              userEmail,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            onTap: () {
              AppRouter.pushNamed(context, AppRoutes.profileEdit);
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  SECTION APPAREANCE
  // ============================================================

  Widget _buildAppearanceSection(bool isDark, SettingsProvider settings) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Apparence',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Mode sombre'),
            subtitle: Text(
              settings.darkMode
                  ? 'Thème sombre activé'
                  : 'Thème clair activé',
            ),
            value: settings.darkMode,
            onChanged: (value) async {
              await settings.toggleDarkMode(value);
              if (context.mounted) {
                // Notifier le changement de thème
              }
            },
            activeColor: AppColors.primary,
            secondary: Icon(
              settings.darkMode ? Icons.dark_mode : Icons.light_mode,
              color: settings.darkMode ? Colors.amber : Colors.orange,
            ),
          ),
          // Langue
          ListTile(
            leading: const Icon(Icons.language, color: AppColors.textSecondary),
            title: const Text('Langue'),
            subtitle: Text(_getLanguageLabel(settings.language)),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
            onTap: () => _showLanguageDialog(context, settings),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  SECTION NOTIFICATIONS
  // ============================================================

  Widget _buildNotificationsSection(bool isDark, SettingsProvider settings) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Notifications push'),
            subtitle: Text(
              settings.notifications
                  ? 'Notifications activées'
                  : 'Notifications désactivées',
            ),
            value: settings.notifications,
            onChanged: (value) async {
              await settings.toggleNotifications(value);
            },
            activeColor: AppColors.primary,
            secondary: Icon(
              settings.notifications
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: settings.notifications
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
          SwitchListTile(
            title: const Text('Effets sonores'),
            subtitle: Text(
              settings.soundEffects
                  ? 'Sons activés'
                  : 'Sons désactivés',
            ),
            value: settings.soundEffects,
            onChanged: (value) async {
              await settings.toggleSoundEffects(value);
            },
            activeColor: AppColors.primary,
            secondary: Icon(
              settings.soundEffects ? Icons.volume_up : Icons.volume_off,
              color: settings.soundEffects
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  SECTION PRÉFÉRENCES
  // ============================================================

  Widget _buildPreferencesSection(bool isDark, SettingsProvider settings) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Préférences',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Sauvegarde automatique'),
            subtitle: Text(
              settings.autoSave
                  ? 'Sauvegarde activée'
                  : 'Sauvegarde désactivée',
            ),
            value: settings.autoSave,
            onChanged: (value) async {
              await settings.toggleAutoSave(value);
            },
            activeColor: AppColors.primary,
            secondary: Icon(
              settings.autoSave ? Icons.save : Icons.save_outlined,
              color: settings.autoSave
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  SECTION COMPTE
  // ============================================================

  Widget _buildAccountSection(bool isDark, AuthProvider auth) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Compte',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
            title: const Text('Changer le mot de passe'),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
            onTap: () => _showChangePasswordDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text(
              'Supprimer le compte',
              style: TextStyle(color: AppColors.error),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.error,
            ),
            onTap: () => _showDeleteAccountDialog(context, auth),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Guide Scolaire',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  SECTION À PROPOS
  // ============================================================

  Widget _buildAboutSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'À propos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.textSecondary),
            title: const Text('À propos de E-learningAI'),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
            onTap: () => _showAboutDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.textSecondary),
            title: const Text('Aide et support'),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
            onTap: () => _showSupportDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline, color: AppColors.textSecondary),
            title: const Text('Noter l\'application'),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
            onTap: () => _showRateDialog(context),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  DIALOGUES
  // ============================================================

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLanguage = settings.language;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageTile(
              context,
              code: 'fr',
              label: 'Français',
              icon: '🇫🇷',
              isSelected: currentLanguage == 'fr',
              onTap: () async {
                await settings.changeLanguage('fr');
                Navigator.pop(context);
              },
            ),
            _buildLanguageTile(
              context,
              code: 'en',
              label: 'English',
              icon: '🇬🇧',
              isSelected: currentLanguage == 'en',
              onTap: () async {
                await settings.changeLanguage('en');
                Navigator.pop(context);
              },
            ),
            _buildLanguageTile(
              context,
              code: 'es',
              label: 'Español',
              icon: '🇪🇸',
              isSelected: currentLanguage == 'es',
              onTap: () async {
                await settings.changeLanguage('es');
                Navigator.pop(context);
              },
            ),
            _buildLanguageTile(
              context,
              code: 'ar',
              label: 'العربية',
              icon: '🇸🇦',
              isSelected: currentLanguage == 'ar',
              onTap: () async {
                await settings.changeLanguage('ar');
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context, {
    required String code,
    required String label,
    required String icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 24)),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Changer le mot de passe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureCurrent ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => obscureCurrent = !obscureCurrent);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => obscureNew = !obscureNew);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => obscureConfirm = !obscureConfirm);
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newPasswordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Les mots de passe ne correspondent pas'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      setState(() => isLoading = true);
                      await Future.delayed(const Duration(seconds: 2));
                      setState(() => isLoading = false);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Mot de passe modifié avec succès'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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
                  : const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthProvider auth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            const Text('Supprimer le compte'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action est irréversible. Toutes vos données seront supprimées.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text(
              'Êtes-vous sûr de vouloir continuer ?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Compte supprimé avec succès'),
                  backgroundColor: AppColors.error,
                ),
              );
              auth.logout();
              Navigator.pushReplacementNamed(context, '/');
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

  void _showResetDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Réinitialiser les paramètres'),
        content: const Text(
          'Tous vos paramètres seront rétablis aux valeurs par défaut. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await settings.resetSettings();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Paramètres réinitialisés'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'E-learningAI',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Guide Scolaire',
      children: [
        const Text(
          'Plateforme d\'apprentissage intelligente avec IA pour les élèves du collège et lycée.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        const Text(
          '🚀 Développé avec ❤️ pour la communauté éducative.',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  void _showSupportDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Aide et support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email_outlined, color: AppColors.primary),
              title: const Text('Nous contacter'),
              subtitle: const Text('support@elearning-ai.com'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined, color: AppColors.primary),
              title: const Text('Chat en ligne'),
              subtitle: const Text('Disponible 24/7'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: AppColors.primary),
              title: const Text('FAQ'),
              subtitle: const Text('Questions fréquentes'),
              onTap: () {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showRateDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Noter l\'application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Vous aimez E-learningAI ?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre avis nous aide à nous améliorer !',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < 4 ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⭐ Merci pour votre note !'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  UTILITAIRES
  // ============================================================

  String _getLanguageLabel(String code) {
    switch (code) {
      case 'fr':
        return 'Français 🇫🇷';
      case 'en':
        return 'English 🇬🇧';
      case 'es':
        return 'Español 🇪🇸';
      case 'ar':
        return 'العربية 🇸🇦';
      default:
        return 'Français 🇫🇷';
    }
  }
}