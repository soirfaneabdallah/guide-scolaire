// frontend/lib/features/videos/presentation/widgets/video_topic_input.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class VideoTopicInput extends StatelessWidget {
  const VideoTopicInput({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Décris ce que tu veux apprendre',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textWhite : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 5,
            minLines: 3,
            maxLength: 500,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.textWhite : AppColors.textPrimary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'Ex: "Explique-moi le théorème de Pythagore avec une démonstration visuelle"',
              hintStyle: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
                height: 1.5,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              return Text(
                '${value.text.length} / 500',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}