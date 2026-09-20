// frontend/lib/features/videos/presentation/widgets/video_card_horizontal.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/video_script.dart';
import 'video_thumbnail.dart';

class VideoCardHorizontal extends StatelessWidget {
  const VideoCardHorizontal({
    super.key,
    required this.video,
    required this.subjectColor,
    required this.onTap,
  });

  final VideoScript video;
  final Color subjectColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = video.userProgress?.completed ?? false;

    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VideoThumbnail(
              thumbnailUrl: video.thumbnailUrl,
              title: video.title,
              subjectColor: subjectColor,
              isCompleted: isCompleted,
              height: 110,
              borderRadius: 14,
            ),
            const SizedBox(height: 8),
            Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                height: 1.3,
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video.level,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: subjectColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}