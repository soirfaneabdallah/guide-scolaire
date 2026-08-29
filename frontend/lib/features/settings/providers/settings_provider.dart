// frontend/lib/features/settings/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _loadSettings();
  }

  AppSettings _settings = AppSettings();
  bool _isLoading = false;

  // ============================================================
  //  GETTERS
  // ============================================================

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get darkMode => _settings.darkMode;
  bool get notifications => _settings.notifications;
  bool get soundEffects => _settings.soundEffects;
  String get language => _settings.language;
  bool get autoSave => _settings.autoSave;

  // ============================================================
  //  CHARGEMENT
  // ============================================================

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      final settings = AppSettings(
        darkMode: prefs.getBool('dark_mode') ?? false,
        notifications: prefs.getBool('notifications') ?? true,
        soundEffects: prefs.getBool('sound_effects') ?? true,
        language: prefs.getString('language') ?? 'fr',
        autoSave: prefs.getBool('auto_save') ?? true,
        fontSize: prefs.getInt('font_size'),
        themeColor: prefs.getString('theme_color'),
      );

      _settings = settings;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  //  MISE À JOUR
  // ============================================================

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('dark_mode', _settings.darkMode);
      await prefs.setBool('notifications', _settings.notifications);
      await prefs.setBool('sound_effects', _settings.soundEffects);
      await prefs.setString('language', _settings.language);
      await prefs.setBool('auto_save', _settings.autoSave);
      
      if (_settings.fontSize != null) {
        await prefs.setInt('font_size', _settings.fontSize!);
      }
      if (_settings.themeColor != null) {
        await prefs.setString('theme_color', _settings.themeColor!);
      }
    } catch (e) {
      print('❌ Erreur sauvegarde paramètres: $e');
    }
  }

  // ============================================================
  //  MÉTHODES INDIVIDUELLES
  // ============================================================

  Future<void> toggleDarkMode(bool value) async {
    _settings = _settings.copyWith(darkMode: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _settings = _settings.copyWith(notifications: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleSoundEffects(bool value) async {
    _settings = _settings.copyWith(soundEffects: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleAutoSave(bool value) async {
    _settings = _settings.copyWith(autoSave: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> changeLanguage(String language) async {
    _settings = _settings.copyWith(language: language);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> resetSettings() async {
    _settings = AppSettings();
    await _saveSettings();
    notifyListeners();
  }

  void dispose() {
    // Nettoyage si nécessaire
  }
}