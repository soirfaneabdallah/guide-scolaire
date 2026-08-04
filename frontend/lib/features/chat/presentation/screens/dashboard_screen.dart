// frontend/lib/features/chat/presentation/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
//import '../../../../core/routing/app_router.dart';
import '../../../auth/providers/auth_provider.dart';
//import '../providers/chat_provider.dart';
import '../../../../core/routing/app_routes.dart';     

/// Écran d'accueil après connexion.
/// Permet de poser une question rapidement ou d'ouvrir le chat complet.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
      return const SizedBox.shrink();
    }

    final userName = authProvider.userName ?? 'Élève';
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, userName),
              const SizedBox(height: 28),

              // Zone de saisie
              _buildInputZone(context),
              const SizedBox(height: 24),

              // Suggestions
              _buildSuggestions(context),
              const Spacer(),

              // Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, $userName 👋',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Comment puis-je t\'aider aujourd\'hui ?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Semantics(
          label: 'Profil utilisateur',
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputZone(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.chat);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'Pose ta question...',
            hintStyle: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.chat_outlined,
              color: AppColors.textDisabled,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    final suggestions = [
      'Explique-moi les fractions',
      'Comment conjuguer au passé composé ?',
      'Théorème de Pythagore',
      'Calculer une moyenne',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💡 Suggestions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map(
                (label) => _SuggestionChip(
                  label: label,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chat,
                      arguments: {'question': label},
                    );
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        '🧠 Assistant éducatif des Comores',
        style: TextStyle(
          color: AppColors.textDisabled.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Suggestion: $label',
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: Colors.white,
        side: const BorderSide(
          color: AppColors.divider,
          width: 1,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}