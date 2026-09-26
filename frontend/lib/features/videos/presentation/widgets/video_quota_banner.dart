// frontend/lib/features/videos/presentation/widgets/video_quota_banner.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/video_generation_provider.dart';

class VideoQuotaBanner extends StatelessWidget {
  const VideoQuotaBanner({super.key, required this.provider});

  final VideoGenerationProvider provider;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ============================================================
    // CHARGEMENT
    // ============================================================
    if (provider.isLoadingQuota) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Chargement du quota...',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    // ============================================================
    // PAS DE QUOTA
    // ============================================================
    final quota = provider.quota;
    if (quota == null) {
      return const SizedBox.shrink();
    }

    // ============================================================
    // CALCULS
    // ============================================================
    final usedMinutes = (quota.usedSecondsToday / 60).ceil();
    final limitMinutes = (quota.dailyLimitSeconds / 60).ceil();
    final remainingMinutes = (quota.remainingSeconds / 60).ceil();
    final progress = quota.dailyLimitSeconds > 0
        ? quota.remainingSeconds / quota.dailyLimitSeconds
        : 0.0;
    final isLow = remainingMinutes < 5;
    final isExceeded = remainingMinutes <= 0;

    // ============================================================
    // UI
    // ============================================================
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLow || isExceeded
              ? AppColors.warning.withOpacity(0.3)
              : (isDark ? AppColors.borderDark : AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============================================================
          // EN-TÊTE
          // ============================================================
          Row(
            children: [
              Icon(
                isExceeded
                    ? Icons.block
                    : (isLow
                        ? Icons.warning_amber_rounded
                        : Icons.timer_outlined),
                size: 16,
                color: isLow || isExceeded
                    ? AppColors.warning
                    : AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                'Quota vidéo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isLow || isExceeded
                      ? AppColors.warning
                      : AppColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              // ✅ TEXTE EXPLICITE
              Text(
                isExceeded
                    ? 'Quota épuisé'
                    : '$remainingMinutes min restantes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isLow || isExceeded
                      ? AppColors.warning
                      : (isDark
                          ? AppColors.textWhite
                          : AppColors.textPrimary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ============================================================
          // BARRE DE PROGRESSION
          // ============================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor:
                  isDark ? AppColors.borderDark : AppColors.border,
              valueColor: AlwaysStoppedAnimation(
                isLow || isExceeded
                    ? AppColors.warning
                    : (isDark ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ============================================================
          // DÉTAIL (utilisé / total)
          // ============================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Utilisé : $usedMinutes min',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                'Total : $limitMinutes min',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),

          // ============================================================
          // MESSAGE D'ALERTE (si bas)
          // ============================================================
          if (isLow && !isExceeded) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Il te reste peu de temps de vidéo aujourd\'hui.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ============================================================
          // MESSAGE SI ÉPUISÉ
          // ============================================================
          if (isExceeded) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.block,
                    size: 14,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Quota journalier atteint. Reviens demain !',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}