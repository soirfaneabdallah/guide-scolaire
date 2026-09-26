// frontend/lib/features/videos/presentation/widgets/video_generation_progress.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/video_generation_provider.dart';

class VideoGenerationProgress extends StatelessWidget {
  const VideoGenerationProgress({
    super.key,
    required this.provider,
  });

  final VideoGenerationProvider provider;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        title: Text(
          'Génération en cours',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textWhite : AppColors.textPrimary,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            // Chronomètre
            Text(
              provider.formattedElapsed,
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w200,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Temps écoulé',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 48),

            // Barre
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: provider.progress / 100,
                minHeight: 8,
                backgroundColor:
                    isDark ? AppColors.borderDark : AppColors.border,
                valueColor: AlwaysStoppedAnimation(
                  isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.stepLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${provider.progress}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),
            _buildSteps(provider, isDark),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => provider.cancelGeneration(),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSteps(VideoGenerationProvider provider, bool isDark) {
    final steps = [
      (GenerationStep.analyzing, 'Analyse de la demande'),
      (GenerationStep.generatingCode, 'Génération du code'),
      (GenerationStep.rendering, 'Rendu de l\'animation'),
      (GenerationStep.synthesizing, 'Synthèse vocale'),
      (GenerationStep.assembling, 'Montage final'),
    ];

    return Column(
      children: steps.map((entry) {
        final step = entry.$1;
        final label = entry.$2;
        final isDone = _isStepDone(provider.step, step);
        final isCurrent = provider.step == step;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isDone
                      ? (isDark ? Colors.white : AppColors.textPrimary)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone || isCurrent
                        ? (isDark ? Colors.white : AppColors.textPrimary)
                        : (isDark ? AppColors.borderDark : AppColors.border),
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? Icon(
                        Icons.check,
                        size: 12,
                        color: isDark ? AppColors.textPrimary : Colors.white,
                      )
                    : (isCurrent
                        ? Center(
                            child: SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          )
                        : null),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isDone || isCurrent
                      ? (isDark ? Colors.white : AppColors.textPrimary)
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _isStepDone(GenerationStep current, GenerationStep step) {
    const order = [
      GenerationStep.analyzing,
      GenerationStep.generatingCode,
      GenerationStep.rendering,
      GenerationStep.synthesizing,
      GenerationStep.assembling,
      GenerationStep.ready,
    ];
    return order.indexOf(current) > order.indexOf(step);
  }
}