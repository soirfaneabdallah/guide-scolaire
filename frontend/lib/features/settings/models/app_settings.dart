// frontend/lib/features/settings/models/app_settings.dart

class AppSettings {
  final bool darkMode;
  final bool notifications;
  final bool soundEffects;
  final String language;
  final bool autoSave;
  final int? fontSize;
  final String? themeColor;

  AppSettings({
    this.darkMode = false,
    this.notifications = true,
    this.soundEffects = true,
    this.language = 'fr',
    this.autoSave = true,
    this.fontSize,
    this.themeColor,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      darkMode: json['dark_mode'] ?? false,
      notifications: json['notifications'] ?? true,
      soundEffects: json['sound_effects'] ?? true,
      language: json['language'] ?? 'fr',
      autoSave: json['auto_save'] ?? true,
      fontSize: json['font_size'],
      themeColor: json['theme_color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dark_mode': darkMode,
      'notifications': notifications,
      'sound_effects': soundEffects,
      'language': language,
      'auto_save': autoSave,
      'font_size': fontSize,
      'theme_color': themeColor,
    };
  }

  AppSettings copyWith({
    bool? darkMode,
    bool? notifications,
    bool? soundEffects,
    String? language,
    bool? autoSave,
    int? fontSize,
    String? themeColor,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      notifications: notifications ?? this.notifications,
      soundEffects: soundEffects ?? this.soundEffects,
      language: language ?? this.language,
      autoSave: autoSave ?? this.autoSave,
      fontSize: fontSize ?? this.fontSize,
      themeColor: themeColor ?? this.themeColor,
    );
  }
}