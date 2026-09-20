// frontend/lib/features/chat/presentation/providers/video_quota_provider.dart

import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';

/// Provider pour gérer le quota vidéo de l'utilisateur.
class VideoQuotaProvider extends ChangeNotifier {
  VideoQuotaProvider(this._apiClient);

  final ApiClient _apiClient;

  int _remainingSeconds = 1800; // 30 min par défaut
  int _usedSecondsToday = 0;
  int _dailyLimitSeconds = 1800;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdate;

  // ============================================================
  // GETTERS
  // ============================================================

  /// Minutes restantes aujourd'hui
  int get remainingMinutes => (_remainingSeconds / 60).ceil();

  /// Minutes utilisées aujourd'hui
  int get usedMinutes => (_usedSecondsToday / 60).ceil();

  /// Limite journalière en minutes
  int get dailyLimitMinutes => (_dailyLimitSeconds / 60).ceil();

  /// Le quota est-il épuisé ?
  bool get isExceeded => _remainingSeconds <= 0;

  /// Le quota est-il presque épuisé ? (< 5 min)
  bool get isLow => _remainingSeconds > 0 && _remainingSeconds < 300;

  /// Pourcentage utilisé
  double get usedPercentage {
    if (_dailyLimitSeconds == 0) return 0;
    return (_usedSecondsToday / _dailyLimitSeconds).clamp(0.0, 1.0);
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================================
  // CHARGEMENT
  // ============================================================

  /// Charge le quota depuis le backend
  Future<void> loadQuota() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/videos/quota');
      final data = response.data;

      _remainingSeconds = data['remaining_seconds'] ?? 1800;
      _usedSecondsToday = data['used_seconds_today'] ?? 0;
      _dailyLimitSeconds = data['daily_limit_seconds'] ?? 1800;
      _lastUpdate = DateTime.now();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Erreur chargement quota: $e');
    }
  }

  /// Rafraîchit le quota si nécessaire (toutes les 2 min)
  Future<void> refreshIfNeeded() async {
    if (_lastUpdate == null ||
        DateTime.now().difference(_lastUpdate!).inMinutes >= 2) {
      await loadQuota();
    }
  }

  /// Utilise une certaine quantité de quota
  void consumeQuota(int seconds) {
    _usedSecondsToday += seconds;
    _remainingSeconds =
        (_dailyLimitSeconds - _usedSecondsToday).clamp(0, _dailyLimitSeconds);
    _lastUpdate = DateTime.now();
    notifyListeners();
  }

  /// Réinitialise (pour les tests)
  void reset() {
    _remainingSeconds = 1800;
    _usedSecondsToday = 0;
    _dailyLimitSeconds = 1800;
    _error = null;
    _lastUpdate = null;
    notifyListeners();
  }
}