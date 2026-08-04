// frontend/lib/features/cahier/presentation/screens/cahier_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/cahier_provider.dart';
import '../widgets/cahier_canvas.dart';
import '../widgets/cahier_toolbar.dart';

class CahierScreen extends StatefulWidget {
  const CahierScreen({super.key});

  @override
  State<CahierScreen> createState() => _CahierScreenState();
}

class _CahierScreenState extends State<CahierScreen> {
  final String _pageTitle = 'Cahier de correction';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(_pageTitle),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        actions: [
          // Bouton d'export (à venir)
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () {
              // TODO: Sauvegarder/enregistrer
            },
            tooltip: 'Sauvegarder',
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined),
            onPressed: () {
              // TODO: Envoyer à l'IA pour correction
            },
            tooltip: 'Envoyer à l\'IA pour correction',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 16),
        child: Column(
          children: [
            // Barre d'outils
            const CahierToolbar(),
            const SizedBox(height: 16),

            // Zone de dessin
            const Expanded(
              child: CahierCanvas(),
            ),

            const SizedBox(height: 16),

            // Informations en bas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer<CahierProvider>(
                    builder: (context, provider, _) {
                      return Text(
                        'Trait: ${provider.strokeWidth}px',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      );
                    },
                  ),
                  Text(
                    '✍️ Corrigé par l\'IA bientôt disponible',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}