// frontend/lib/features/videos/presentation/widgets/chapter_section.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/video_script.dart';

/// Section d'un chapitre avec ses vidéos.
class ChapterSection extends StatelessWidget {
  const ChapterSection({
    super.key,
    required this.chapterName,
    required this.videos,
    required this.subjectColor,
    required this.onVideoTap,
    this.chapterIcon,
    this.chapterColor,
    this.isExpanded = true,
    this.onToggle,
  });

  final String chapterName;
  final String? chapterIcon;
  final Color? chapterColor;
  final List<VideoScript> videos;
  final Color subjectColor;
  final ValueChanged<VideoScript> onVideoTap;
  final bool isExpanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = chapterColor ?? subjectColor;

    // Calculer la progression
    final completedCount =
        videos.where((v) => v.userProgress?.completed == true).length;
    final totalCount = videos.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // ============================================================
          // EN-TÊTE DU CHAPITRE
          // ============================================================
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Icône du chapitre
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: chapterIcon != null
                              ? Text(
                                  chapterIcon!,
                                  style: const TextStyle(fontSize: 22),
                                )
                              : Icon(
                                  Icons.folder_outlined,
                                  color: color,
                                  size: 22,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Nom + nombre de vidéos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapterName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textWhite
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$completedCount / $totalCount vidéos',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Flèche
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),

                  // Barre de progression
                  if (totalCount > 0) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? AppColors.borderDark
                            : AppColors.border,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ============================================================
          // LISTE DES VIDÉOS (si déplié)
          // ============================================================
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
                ...videos.map((video) => _buildVideoTile(
                      context: context,
                      video: video,
                      isDark: isDark,
                      color: color,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TUILE VIDÉO (format compact)
  // ============================================================

  Widget _buildVideoTile({
    required BuildContext context,
    required VideoScript video,
    required bool isDark,
    required Color color,
  }) {
    final isCompleted = video.userProgress?.completed ?? false;
    final watched = video.userProgress?.watchedSeconds ?? 0;
    final total = video.estimatedDurationSeconds.toDouble();
    final progress = total > 0 ? (watched / total).clamp(0.0, 1.0) : 0.0;
    final isStarted = progress > 0 && !isCompleted;

    return InkWell(
      onTap: () => onVideoTap(video),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Pastille de statut
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? color
                    : (isStarted
                        ? color.withOpacity(0.2)
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.border)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : (isStarted
                        ? Icon(
                            Icons.play_arrow_rounded,
                            color: color,
                            size: 14,
                          )
                        : null),
              ),
            ),
            const SizedBox(width: 12),

            // Titre + métadonnées
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textWhite
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 11,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        video.formattedDuration,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (video.ratingAverage > 0) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.star,
                          size: 11,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          video.ratingAverage.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Flèche
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}