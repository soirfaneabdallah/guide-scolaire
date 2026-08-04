// frontend/lib/features/exercices/presentation/screens/exercices_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/exercices_provider.dart';
import '../widgets/exercice_stats.dart';
import '../widgets/exercice_filter.dart';
import '../widgets/exercice_card.dart';
import 'exercice_detail_screen.dart';

class ExercicesScreen extends StatefulWidget {
  const ExercicesScreen({super.key});

  @override
  State<ExercicesScreen> createState() => _ExercicesScreenState();
}

class _ExercicesScreenState extends State<ExercicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExercicesProvider>().loadExercices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExercicesProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('📝 Mes exercices'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadExercices(),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                children: [
                  const ExerciceStats(),
                  const SizedBox(height: 16),
                  const ExerciceFilter(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: provider.hasExercices
                        ? ListView.builder(
                            itemCount: provider.exercices.length,
                            itemBuilder: (context, index) {
                              final exercice = provider.exercices[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ExerciceCard(
                                  exercice: exercice,
                                  onTap: () {
                                    // ✅ Passer l'exercice directement au lieu d'utiliser le provider
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ExerciceDetailScreen(
                                          exercice: exercice,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 64,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun exercice trouvé',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Essayez de modifier vos filtres',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}