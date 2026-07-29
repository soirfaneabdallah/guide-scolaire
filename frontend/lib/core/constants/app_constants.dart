// frontend/lib/core/constants/app_constants.dart

import 'package:flutter/material.dart';

/// Constantes globales de l'application.
class AppConstants {
  AppConstants._();

  /// Durée des animations de transition (en millisecondes)
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Durée des animations de fade
  static const Duration fadeDuration = Duration(milliseconds: 200);

  /// Courbe d'animation standard
  static const Curve animationCurve = Curves.easeInOut;

  /// Délai de timeout pour les appels réseau (en secondes)
  static const int networkTimeoutSeconds = 30;

  /// Nombre maximum de messages dans l'historique du chat
  static const int maxChatHistory = 100;

  /// Taille de l'avatar utilisateur
  static const double avatarSize = 40.0;

  /// Rayon de bordure standard
  static const double borderRadius = 12.0;

  /// Rayon de bordure des cartes
  static const double cardBorderRadius = 16.0;

  /// Padding standard
  static const EdgeInsets padding = EdgeInsets.all(16.0);

  /// Padding horizontal standard
  static const EdgeInsets paddingHorizontal = EdgeInsets.symmetric(horizontal: 16.0);

  /// Padding vertical standard
  static const EdgeInsets paddingVertical = EdgeInsets.symmetric(vertical: 12.0);
}