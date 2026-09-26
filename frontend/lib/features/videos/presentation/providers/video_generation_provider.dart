// frontend/lib/features/videos/presentation/providers/video_generation_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/video_job_model.dart';
import '../../data/models/video_quota_model.dart';
import '../../data/models/video_request_model.dart';
import '../../data/services/video_generation_service.dart';

// ============================================================
// ÉTAPES DE GÉNÉRATION
// ============================================================

enum GenerationStep {
  idle,
  analyzing,
  generatingCode,
  rendering,
  synthesizing,
  assembling,
  ready,
  error,
}

// ============================================================
// PROVIDER
// ============================================================

class VideoGenerationProvider extends ChangeNotifier {
  VideoGenerationProvider({
    required VideoGenerationService service,
  }) : _service = service;

  final VideoGenerationService _service;

  // Job
  VideoJobModel? _currentJob;
  String? _error;

  // Quota
  VideoQuotaModel? _quota;
  bool _isLoadingQuota = false;

  // Timers
  Timer? _timer;
  Timer? _pollingTimer;
  int _elapsedSeconds = 0;

  // ============================================================
  // GETTERS - JOB
  // ============================================================

  VideoJobModel? get currentJob => _currentJob;
  String? get error => _error;

  bool get isGenerating {
    if (_currentJob == null) return false;
    final s = _currentJob!.status;
    return s != 'ready' && s != 'failed' && s != 'cancelled';
  }

  GenerationStep get step {
    if (_currentJob == null) return GenerationStep.idle;
    return _statusToStep(_currentJob!.status);
  }

  int get progress => _currentJob?.progress ?? 0;
  int get elapsedSeconds => _elapsedSeconds;
  String? get videoUrl => _currentJob?.videoUrl;

  String get stepLabel {
    switch (step) {
      case GenerationStep.idle:
        return 'Prêt';
      case GenerationStep.analyzing:
        return 'Analyse de la demande...';
      case GenerationStep.generatingCode:
        return 'Génération du code Manim...';
      case GenerationStep.rendering:
        return 'Rendu de l\'animation...';
      case GenerationStep.synthesizing:
        return 'Synthèse vocale...';
      case GenerationStep.assembling:
        return 'Montage final...';
      case GenerationStep.ready:
        return 'Vidéo prête !';
      case GenerationStep.error:
        return 'Erreur';
    }
  }

  String get formattedElapsed {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // GETTERS - QUOTA
  // ============================================================

  VideoQuotaModel? get quota => _quota;
  bool get isLoadingQuota => _isLoadingQuota;
  bool get canGenerate => _quota?.canGenerate ?? true;
  int get quotaRemainingMinutes => _quota?.remainingMinutes ?? 0;
  int get quotaDailyLimitMinutes => _quota?.dailyLimitMinutes ?? 30;
  double get quotaProgress {
    if (_quota == null) return 0;
    return _quota!.remainingSeconds / _quota!.dailyLimitSeconds;
  }

  // ============================================================
  // CHARGER LE QUOTA
  // ============================================================

  Future<void> loadQuota() async {
    _isLoadingQuota = true;
    notifyListeners();

    try {
      _quota = await _service.getQuota();
      _isLoadingQuota = false;
      notifyListeners();
    } catch (e) {
      _isLoadingQuota = false;
      debugPrint('❌ Erreur chargement quota : $e');
      notifyListeners();
    }
  }

  // ============================================================
  // LANCER UNE GÉNÉRATION
  // ============================================================

  Future<bool> startGeneration({
    required String prompt,
    required int subjectId,
    String? level,
    int durationSeconds = 180,
  }) async {
    if (!canGenerate) {
      _error = 'Quota journalier atteint';
      notifyListeners();
      return false;
    }

    // Reset
    _currentJob = null;
    _error = null;
    _elapsedSeconds = 0;
    notifyListeners();

    try {
      final request = VideoRequestModel(
        prompt: prompt,
        subjectId: subjectId,
        level: level,
        durationSeconds: durationSeconds,
      );

      final data = await _service.startGeneration(request);

      // ✅ CORRECTION : Convertir en int explicitement
      final estimatedSeconds =
          (data['estimated_time_seconds'] as num?)?.toInt() ?? 360;

      final quotaRemainingSeconds =
          (data['quota_remaining_seconds'] as num?)?.toInt() ?? 0;

      // Créer un job local
      _currentJob = VideoJobModel(
        id: data['job_id']?.toString() ?? '',
        userId: 0,
        promptContext: prompt,
        status: 'pending',
        progress: 0,
        estimatedDurationSeconds: estimatedSeconds,
        createdAt: DateTime.now(),
      );

      // Mettre à jour le quota
      if (_quota != null) {
        _quota = VideoQuotaModel(
          id: _quota!.id,
          userId: _quota!.userId,
          tier: _quota!.tier,
          dailyLimitSeconds: _quota!.dailyLimitSeconds,
          usedSecondsToday:
              _quota!.dailyLimitSeconds - quotaRemainingSeconds,
          remainingSeconds: quotaRemainingSeconds,
          usedPercentage: _quota!.usedPercentage,
          canGenerate: quotaRemainingSeconds > 0,
        );
      }

      notifyListeners();

      // Démarrer le chronomètre
      _startTimer();

      // Démarrer le polling
      _startPolling();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // CHRONOMÈTRE
  // ============================================================

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ============================================================
  // POLLING DU STATUT
  // ============================================================

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_currentJob == null || _currentJob!.id.isEmpty) return;

      try {
        final updated = await _service.getJobStatus(_currentJob!.id);
        _currentJob = updated;

        // Si terminé
        if (updated.status == 'ready' ||
            updated.status == 'failed' ||
            updated.status == 'cancelled') {
          _pollingTimer?.cancel();
          _stopTimer();
        }

        notifyListeners();
      } catch (e) {
        debugPrint('❌ Erreur polling : $e');
      }
    });
  }

  // ============================================================
  // ANNULER
  // ============================================================

  Future<void> cancelGeneration() async {
    if (_currentJob != null && _currentJob!.id.isNotEmpty) {
      try {
        await _service.cancelJob(_currentJob!.id);
      } catch (e) {
        debugPrint('❌ Erreur annulation : $e');
      }
    }
    _stopTimer();
    _pollingTimer?.cancel();
    _reset();
  }

  // ============================================================
  // RESET
  // ============================================================

  void _reset() {
    _currentJob = null;
    _error = null;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  void reset() {
    _stopTimer();
    _pollingTimer?.cancel();
    _reset();
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  GenerationStep _statusToStep(String status) {
    switch (status) {
      case 'pending':
        return GenerationStep.analyzing;
      case 'generating_code':
        return GenerationStep.generatingCode;
      case 'rendering':
        return GenerationStep.rendering;
      case 'synthesizing':
        return GenerationStep.synthesizing;
      case 'assembling':
        return GenerationStep.assembling;
      case 'ready':
        return GenerationStep.ready;
      case 'failed':
      case 'cancelled':
        return GenerationStep.error;
      default:
        return GenerationStep.analyzing;
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _pollingTimer?.cancel();
    super.dispose();
  }
}