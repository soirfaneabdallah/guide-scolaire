// frontend/lib/features/videos/presentation/widgets/video_thumbnail.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({
    super.key,
    required this.thumbnailUrl,
    required this.title,
    required this.subjectColor,
    this.isCompleted = false,
    this.showPlayButton = true,
    this.borderRadius = 12,
    this.width,
    this.height,
  });

  final String? thumbnailUrl;
  final String title;
  final Color subjectColor;
  final bool isCompleted;
  final bool showPlayButton;
  final double borderRadius;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(context),

            // Overlay dégradé
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),

            // Bouton play
            if (showPlayButton)
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: subjectColor,
                    size: 26,
                  ),
                ),
              ),

            // Badge "Terminé"
            if (isCompleted)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: subjectColor,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return Image.network(
        thumbnailUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildPlaceholder(context);
        },
        errorBuilder: (context, error, stack) {
          return _buildPlaceholder(context);
        },
      );
    }
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final hash = title.hashCode;
    final hue = (hash % 360).abs().toDouble();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, hue, 0.55, 0.5).toColor(),
            HSLColor.fromAHSL(1, (hue + 30) % 360, 0.55, 0.4).toColor(),
          ],
        ),
      ),
      child: Center(
        child: Text(
          _getEmoji(title),
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  String _getEmoji(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('pythagore') || lower.contains('triangle')) return '📐';
    if (lower.contains('cercle')) return '⭕';
    if (lower.contains('fonction')) return '📈';
    if (lower.contains('équation') || lower.contains('equation')) return '🟰';
    if (lower.contains('fraction')) return '½';
    if (lower.contains('nombre')) return '🔢';
    if (lower.contains('géométrie') || lower.contains('geometrie')) return '📏';
    if (lower.contains('statistique')) return '📊';
    if (lower.contains('probabilité') || lower.contains('probabilite')) return '🎲';
    if (lower.contains('atome')) return '⚛️';
    if (lower.contains('cellule')) return '🧬';
    if (lower.contains('photosynthèse')) return '🌱';
    if (lower.contains('grammaire')) return '📖';
    if (lower.contains('histoire')) return '🏛️';
    if (lower.contains('géographie') || lower.contains('geographie')) return '🌍';
    if (lower.contains('anglais') || lower.contains('english')) return '🇬🇧';
    return '🎬';
  }
}