// frontend/lib/features/cahier/presentation/screens/cahier_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/cahier_provider.dart';
import '../widgets/cahier_canvas.dart';
import '../widgets/cahier_toolbar.dart';
import '../widgets/cahier_page_controls.dart';

class CahierScreen extends StatefulWidget {
  const CahierScreen({super.key});

  @override
  State<CahierScreen> createState() => _CahierScreenState();
}

class _CahierScreenState extends State<CahierScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ChangeNotifierProvider(
      create: (_) => CahierProvider(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        appBar: AppBar(
          title: const Text('📓 Cahier de correction'),
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.send_outlined),
              onPressed: () {
                // TODO: Envoyer à l'IA
              },
              tooltip: 'Envoyer à l\'IA',
            ),
            Consumer<CahierProvider>(
              builder: (context, provider, _) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: provider.selectedElements.isNotEmpty
                      ? provider.deleteSelected
                      : null,
                  tooltip: 'Supprimer la sélection',
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 8 : 16),
          child: Column(
            children: [
              // Contrôles des pages
              const CahierPageControls(),
              const SizedBox(height: 12),

              // Barre d'outils
              const CahierToolbar(),
              const SizedBox(height: 12),

              // Canvas
              const Expanded(child: CahierCanvas()),

              const SizedBox(height: 12),

              // Informations
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Consumer<CahierProvider>(
                      builder: (context, provider, _) {
                        return Text(
                          '${provider.elements.length} éléments',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        );
                      },
                    ),
                    
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}