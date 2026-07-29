// frontend/lib/features/dashboard/presentation/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../auth/providers/auth_provider.dart';

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

    final userName = authProvider.userName ?? 'élève';
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) greeting = '🌅 Bonjour';
    else if (hour < 18) greeting = '☀️ Bon après-midi';
    else greeting = '🌙 Bonsoir';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Guide Scolaire',
          style: TextStyle(
            color: Color(0xFF1E2937),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF2E7D32),
              child: Text(
                'Y',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            onPressed: () {
              // TODO: Aller au profil
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message de bienvenue
            Text(
              '$greeting, $userName ! 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2937),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pose ta question, ton assistant est là pour t\'aider.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 24),

            // Zone de saisie + bouton
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Pose ta question...',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => _goToChat(context),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => _goToChat(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Suggestions
            const Text(
              '💡 Exemples de questions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),

            _SuggestionChip(
              text: 'Comment résoudre une équation ?',
              onTap: () => _goToChatWith(context, 'Comment résoudre une équation ?'),
            ),
            const SizedBox(height: 8),
            _SuggestionChip(
              text: 'Explique-moi le théorème de Pythagore',
              onTap: () => _goToChatWith(context, 'Explique-moi le théorème de Pythagore'),
            ),
            const SizedBox(height: 8),
            _SuggestionChip(
              text: 'Comment conjuguer le passé simple ?',
              onTap: () => _goToChatWith(context, 'Comment conjuguer le passé simple ?'),
            ),

            const Spacer(),

            // Petit message en bas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF2E7D32),
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  '100% gratuit pour les élèves comoriens',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _goToChat(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.chat);
  }

  void _goToChatWith(BuildContext context, String question) {
    // TODO: Passer la question au chat
    Navigator.pushNamed(
      context,
      AppRoutes.chat,
      arguments: {'question': question},
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF94A3B8),
              size: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF1E2937),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}