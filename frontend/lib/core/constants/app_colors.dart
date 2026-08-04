// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ============================================================
  //  COULEURS PRINCIPALES
  // ============================================================
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ============================================================
  //  COULEURS DE TEXTE (HIÉRARCHIE COMPLÈTE)
  // ============================================================
  static const Color textPrimary = Color(0xFF1E293B);   // Très foncé (titres)
  static const Color textSecondary = Color(0xFF475569); // Moyen foncé
  static const Color textTertiary = Color(0xFF94A3B8);  // Gris clair (labels)
  static const Color textLight = Color(0xFFCBD5E1);     // Gris très clair
  static const Color textDisabled = Color(0xFFE2E8F0);  // Gris presque blanc
  static const Color textWhite = Color(0xFFFFFFFF);     // Blanc
  static const Color textDark = Color(0xFF0F172A);      // Noir profond

  // ============================================================
  //  COULEURS D'ACCENT
  // ============================================================
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentIndigo = Color(0xFF6366F1);

  // ============================================================
  //  COULEURS DE SÉPARATION / BORDURES
  // ============================================================
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFF334155);

  // ============================================================
  //  COULEURS DE FOND (surfaces alternatives)
  // ============================================================
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF1E293B);

  // ============================================================
  //  DÉGRADÉS (Gradients)
  // ============================================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF10B981)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
  );

  // ============================================================
  //  OMBRES (Shadows)
  // ============================================================
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // ============================================================
  //  COULEURS POUR LES ÉTATS (hover, pressed, etc.)
  // ============================================================
  static const Color hoverLight = Color(0xFFF1F5F9);
  static const Color pressedLight = Color(0xFFE2E8F0);
  static const Color hoverDark = Color(0xFF334155);
  static const Color pressedDark = Color(0xFF475569);
}