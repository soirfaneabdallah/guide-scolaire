// frontend/lib/core/utils/icon_utils.dart

import 'package:flutter/material.dart';
import '../constants/app_icons.dart';

/// Classe utilitaire pour la gestion des icônes
class IconUtils {
  const IconUtils._();

  // ============================================================
  //  VÉRIFICATIONS
  // ============================================================
  
  /// Vérifie si une chaîne est un emoji valide
  static bool isValidEmoji(String? value) {
    if (value == null || value.isEmpty) return false;
    
    // Regex pour détecter les emojis
    final emojiRegex = RegExp(
      r'^[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{1F9E0}-\u{1F9FF}\u{1FA70}-\u{1FAFF}\u{1F004}\u{1F0CF}\u{1F18E}\u{1F17A}\u{1F17F}\u{1F6A9}\u{1F3F4}\u{1F3F3}\u{1F9E6}\u{1F9E8}\u{1F9E9}\u{1F9EA}\u{1F9EB}\u{1F9EC}\u{1F9ED}\u{1F9EE}\u{1F9EF}]+$',
      unicode: true,
    );
    return emojiRegex.hasMatch(value.trim());
  }
  
  /// Vérifie si une chaîne est un code hexadécimal de couleur valide
  static bool isValidHexColor(String? value) {
    if (value == null || value.isEmpty) return false;
    
    final colorRegex = RegExp(r'^#?([0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})$');
    return colorRegex.hasMatch(value.replaceAll('#', ''));
  }
  
  /// Vérifie si une icône est valide (soit un emoji, soit un nom d'icône Material)
  static bool isValidIcon(String? value) {
    if (value == null || value.isEmpty) return false;
    return isValidEmoji(value) || _isMaterialIconName(value);
  }
  
  /// Vérifie si le nom correspond à une icône Material
  static bool _isMaterialIconName(String name) {
    try {
      // Tenter de créer une icône Material avec ce nom
      // Note: Cette méthode n'est pas parfaite, mais fonctionne pour la plupart des noms
      final iconData = IconData(
        name.hashCode,
        fontFamily: 'MaterialIcons',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  //  RÉCUPÉRATION DES ICÔNES
  // ============================================================
  
  /// Récupère l'icône correspondant au nom d'une matière
  static String getSubjectIcon(String name) {
    return AppIcons.getSubjectIcon(name);
  }
  
  /// Récupère l'icône à afficher, avec une valeur par défaut
  static String getIconOrDefault(String? icon, String subjectName) {
    if (icon != null && icon.isNotEmpty) {
      if (isValidEmoji(icon)) {
        return icon;
      }
      // Si ce n'est pas un emoji, essayer de trouver une correspondance
      final defaultIcon = getSubjectIcon(subjectName);
      if (defaultIcon != '📚') {
        return defaultIcon;
      }
    }
    return getSubjectIcon(subjectName);
  }
  
  /// Récupère une icône de widget Material Design
  static IconData? getMaterialIconData(String? iconName) {
    if (iconName == null || iconName.isEmpty) return null;
    
    try {
      // Map des noms d'icônes Material populaires
      const iconMap = {
        'school': Icons.school,
        'menu_book': Icons.menu_book,
        'science': Icons.science,
        'calculate': Icons.calculate,
        'history': Icons.history,
        'public': Icons.public,
        'psychology': Icons.psychology,
        'art_track': Icons.art_track,
        'sports': Icons.sports,
        'computer': Icons.computer,
        'code': Icons.code,
        'analytics': Icons.analytics,
        'business': Icons.business,
        'gavel': Icons.gavel,
        'music_note': Icons.music_note,
        'theater_comedy': Icons.theater_comedy,
        'local_dining': Icons.local_dining,
        'local_florist': Icons.local_florist,
        'build': Icons.build,
        'architecture': Icons.architecture,
        'sports_soccer': Icons.sports_soccer,
        'sports_basketball': Icons.sports_basketball,
        'sports_tennis': Icons.sports_tennis,
        'sports_handball': Icons.sports_handball,
        'sports_volleyball': Icons.sports_volleyball,
        'sports_cricket': Icons.sports_cricket,
        'sports_baseball': Icons.sports_baseball,
        'sports_golf': Icons.sports_golf,
        'sports_esports': Icons.sports_esports,
        'sports_martial_arts': Icons.sports_martial_arts,
        'sports_kabaddi': Icons.sports_kabaddi,
        'sports_rugby': Icons.sports_rugby,
        'sports_hockey': Icons.sports_hockey,
        //'sports_skateboarding': Icons.sports_skateboarding,
       // 'sports_surfing': Icons.sports_surfing,
        //'sports_climbing': Icons.sports_climbing,
        'sports_motorsports': Icons.sports_motorsports,
      };
      
      if (iconMap.containsKey(iconName)) {
        return iconMap[iconName];
      }
      
      // Essayer de créer une icône personnalisée
      return IconData(
        iconName.hashCode,
        fontFamily: 'MaterialIcons',
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  //  FORMATAGE
  // ============================================================
  
  /// Nettoie le texte pour n'obtenir que des emojis
  static String extractEmojis(String text) {
    return AppIcons.extractEmojis(text);
  }
  
  /// Formate une couleur hexadécimale pour un affichage propre
  static String formatHexColor(String? color) {
    if (color == null || color.isEmpty) return '';
    if (color.startsWith('#')) return color;
    if (color.length == 6) return '#$color';
    if (color.length == 8 && color.startsWith('0x')) {
      return '#${color.substring(2)}';
    }
    return color;
  }
  
  /// Récupère la couleur à partir d'une chaîne hexadécimale
  static Color? getColorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    
    try {
      String colorString = hex;
      if (colorString.startsWith('#')) {
        colorString = colorString.substring(1);
      }
      if (colorString.startsWith('0x')) {
        colorString = colorString.substring(2);
      }
      
      if (colorString.length == 6) {
        return Color(int.parse('FF$colorString', radix: 16));
      } else if (colorString.length == 8) {
        return Color(int.parse(colorString, radix: 16));
      }
    } catch (_) {
      return null;
    }
    
    return null;
  }

  // ============================================================
  //  GÉNÉRATION
  // ============================================================
  
  /// Génère une couleur aléatoire pour une matière
  static String generateRandomColor() {
    final colors = [
      '#4CAF50', '#2196F3', '#FF9800', '#9C27B0', 
      '#795548', '#F44336', '#00BCD4', '#FF5722',
      '#8BC34A', '#03A9F4', '#FFC107', '#E91E63',
      '#009688', '#673AB7', '#FF6F00', '#004D40',
      '#1A237E', '#B71C1C', '#1B5E20', '#4A148C',
    ];
    return colors[DateTime.now().millisecondsSinceEpoch % colors.length];
  }
  
  /// Génère un slug à partir d'un nom
  static String generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
  
  /// Génère une couleur à partir d'un nom (consistant)
  static String generateColorFromName(String name) {
    final hash = name.hashCode.abs();
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = hash & 0x0000FF;
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }

  // ============================================================
  //  LISTES UTILES
  // ============================================================
  
  /// Récupère la liste des icônes populaires pour les matières
  static List<String> getPopularIcons() {
    return AppIcons.getPopularIcons();
  }
  
  /// Récupère la liste des couleurs populaires
  static List<String> getPopularColors() {
    return [
      '#4CAF50', '#2196F3', '#FF9800', '#9C27B0',
      '#795548', '#F44336', '#00BCD4', '#FF5722',
      '#8BC34A', '#03A9F4', '#FFC107', '#E91E63',
      '#009688', '#673AB7', '#FF6F00', '#004D40',
    ];
  }
  
  /// Récupère la liste des noms d'icônes Material populaires
  static List<String> getMaterialIconNames() {
    return [
      'school', 'menu_book', 'science', 'calculate',
      'history', 'public', 'psychology', 'art_track',
      'sports', 'computer', 'code', 'analytics',
      'business', 'gavel', 'music_note', 'theater_comedy',
      'local_dining', 'local_florist', 'build', 'architecture',
    ];
  }
}