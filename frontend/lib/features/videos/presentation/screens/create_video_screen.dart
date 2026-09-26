// frontend/lib/features/videos/presentation/screens/create_video_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_routes.dart';
import '../../data/services/video_generation_service.dart';
import '../providers/video_generation_provider.dart';
import '../widgets/video_topic_input.dart';
import '../widgets/video_suggestions.dart';
import '../widgets/video_quota_banner.dart';
import '../widgets/video_generation_progress.dart';

class CreateVideoScreen extends StatefulWidget {
  const CreateVideoScreen({
    super.key,
    this.subjectId,
    this.subjectName,
    this.level,
  });

  final int? subjectId;
  final String? subjectName;
  final String? level;

  @override
  State<CreateVideoScreen> createState() => _CreateVideoScreenState();
}

class _CreateVideoScreenState extends State<CreateVideoScreen> {
  final TextEditingController _topicController = TextEditingController();
  late VideoGenerationProvider _provider;
  String? _selectedLevel;

  @override
  void initState() {
    super.initState();

    final apiClient = context.read<ApiClient>();

    _provider = VideoGenerationProvider(
      service: VideoGenerationService(apiClient: apiClient),
    );

    _selectedLevel = widget.level ?? '4ème';

    // ✅ Charger le quota au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.loadQuota();
    });
  }

  @override
  void dispose() {
    _topicController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider<VideoGenerationProvider>.value(
      value: _provider,
      child: Consumer<VideoGenerationProvider>(
        builder: (context, provider, _) {
          // ✅ Si génération en cours → écran de progression
          if (provider.isGenerating) {
            return VideoGenerationProgress(provider: provider);
          }

          // ✅ Si vidéo prête → écran "prête"
          if (provider.step == GenerationStep.ready) {
            return _buildReadyScreen(provider, isDark);
          }

          // ✅ Sinon → écran de création
          return _buildCreateScreen(provider, isDark);
        },
      ),
    );
  }

  // ============================================================
  // ÉCRAN DE CRÉATION
  // ============================================================

  Widget _buildCreateScreen(
    VideoGenerationProvider provider,
    bool isDark,
  ) {
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        title: Text(
          'Créer une vidéo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textWhite : AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.textWhite : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contexte (matière + niveau)
            _buildContextCard(isDark),

            const SizedBox(height: 24),

            // ✅ Quota avec le provider
            VideoQuotaBanner(provider: provider),

            const SizedBox(height: 24),

            // Champ de saisie
            VideoTopicInput(
              controller: _topicController,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),

            // Suggestions
            VideoSuggestions(
              subjectName: widget.subjectName,
              onSuggestionSelected: (suggestion) {
                _topicController.text = suggestion;
                setState(() {});
              },
            ),

            const SizedBox(height: 32),

            // Bouton générer
            _buildGenerateButton(provider, isDark),

            const SizedBox(height: 16),

            // Info
            _buildInfoText(isDark),

            // Erreur
            if (provider.error != null) ...[
              const SizedBox(height: 16),
              _buildError(provider.error!, isDark),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ÉCRAN "VIDÉO PRÊTE"
  // ============================================================

  Widget _buildReadyScreen(
    VideoGenerationProvider provider,
    bool isDark,
  ) {
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        title: Text(
          'Vidéo prête',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textWhite : AppColors.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              const SizedBox(height: 24),
              Text(
                'Vidéo générée !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Durée : ${provider.formattedElapsed}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.videoPlayer,
                      arguments: {
                        'scriptId': provider.currentJob?.id,
                        'videoUrl': provider.videoUrl,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.white : AppColors.textPrimary,
                    foregroundColor:
                        isDark ? AppColors.textPrimary : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Regarder la vidéo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  provider.reset();
                  _topicController.clear();
                  setState(() {});
                },
                child: const Text(
                  'Créer une autre vidéo',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARTE CONTEXTE
  // ============================================================

  Widget _buildContextCard(bool isDark) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Matière',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subjectName ?? 'Général',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Niveau',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: _selectedLevel,
                  underline: const SizedBox(),
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                  dropdownColor:
                      isDark ? AppColors.surfaceDark : Colors.white,
                  items: const [
                    '6ème', '5ème', '4ème', '3ème',
                    'Seconde', 'Première', 'Terminale',
                  ].map((level) {
                    return DropdownMenuItem<String>(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedLevel = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOUTON GÉNÉRER
  // ============================================================

  Widget _buildGenerateButton(
    VideoGenerationProvider provider,
    bool isDark,
  ) {
    final canGenerate = _topicController.text.trim().length >= 3 &&
        !provider.isGenerating &&
        provider.canGenerate;

    String buttonLabel = 'Générer la vidéo';
    if (!provider.canGenerate) {
      buttonLabel = 'Quota atteint';
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: canGenerate ? () => _generateVideo(provider) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : AppColors.textPrimary,
          foregroundColor: isDark ? AppColors.textPrimary : Colors.white,
          disabledBackgroundColor:
              isDark ? AppColors.borderDark : AppColors.border,
          disabledForegroundColor: AppColors.textTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_creation_outlined,
              size: 20,
              color: canGenerate
                  ? (isDark ? AppColors.textPrimary : Colors.white)
                  : AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              buttonLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: canGenerate
                    ? (isDark ? AppColors.textPrimary : Colors.white)
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO
  // ============================================================

  Widget _buildInfoText(bool isDark) {
    return const Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 14,
          color: AppColors.textTertiary,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'La génération prend environ 3 à 6 minutes. Vous serez notifié.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERREUR
  // ============================================================

  Widget _buildError(String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LANCER LA GÉNÉRATION
  // ============================================================

  Future<void> _generateVideo(VideoGenerationProvider provider) async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;

    final subjectId = widget.subjectId ?? 1;

    await provider.startGeneration(
      prompt: topic,
      subjectId: subjectId,
      level: _selectedLevel,
    );
  }
}