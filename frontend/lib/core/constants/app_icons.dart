// frontend/lib/core/constants/app_icons.dart

/// Constantes pour les icônes de l'application
class AppIcons {
  // ============================================================
  //  ICÔNES PAR DÉFAUT POUR LES MATIÈRES
  // ============================================================
  
  static const Map<String, String> subjectIcons = {
    // Sciences
    'mathématiques': '📐',
    'math': '📐',
    'algèbre': '🔢',
    'géométrie': '📐',
    'calcul': '🧮',
    'physique': '⚡',
    'chimie': '🧪',
    'svt': '🧬',
    'biologie': '🧬',
    'sciences': '🔬',
    'science': '🔬',
    'astronomie': '🌌',
    
    // Langues
    'français': '📖',
    'littérature': '📚',
    'poésie': '📝',
    'anglais': '🗣️',
    'espagnol': '🇪🇸',
    'allemand': '🇩🇪',
    'italien': '🇮🇹',
    'latin': '🏛️',
    'grec': '🏛️',
    'japonais': '🇯🇵',
    'chinois': '🇨🇳',
    'russe': '🇷🇺',
    'arabe': '🇸🇦',
    
    // Humanités
    'histoire': '🏛️',
    'géographie': '🌍',
    'philosophie': '💭',
    'psychologie': '🧠',
    'sociologie': '👥',
    'économie': '📊',
    'gestion': '📋',
    'commerce': '💰',
    'droit': '⚖️',
    'politique': '🏛️',
    'religion': '⛪',
    'culture': '🎭',
    
    // Arts
    'art': '🎨',
    'musique': '🎵',
    'théâtre': '🎭',
    'danse': '💃',
    'cinéma': '🎬',
    'photographie': '📸',
    'dessin': '✏️',
    'peinture': '🎨',
    'sculpture': '🗿',
    
    // Sport
    'sport': '⚽',
    'éducation physique': '🏃',
    'athlétisme': '🏃',
    'basketball': '🏀',
    'football': '⚽',
    'tennis': '🎾',
    'natation': '🏊',
    'yoga': '🧘',
    
    // Technologies
    'informatique': '💻',
    'programmation': '💻',
    'développement': '💻',
    'web': '🌐',
    'mobile': '📱',
    'ia': '🤖',
    'intelligence artificielle': '🤖',
    'robotique': '🤖',
    'data': '📊',
    'cybersécurité': '🔒',
    'réseaux': '📡',
    
    // Autres
    'pédagogie': '🧑‍🏫',
    'éducation': '🎓',
    'étude': '📖',
    'recherche': '🔍',
    'projet': '📋',
    'travail': '📋',
    'mémoire': '🧠',
    'test': '✍️',
    'examen': '📝',
    'concours': '🏆',
    
    // Divers
    'cuisine': '🍳',
    'jardinage': '🌱',
    'bricolage': '🔧',
    'couture': '🧵',
    'menuiserie': '🪚',
    'électronique': '🔌',
    'mécanique': '🔧',
    'architecture': '🏗️',
    'design': '✏️',
    'mode': '👗',
  };

  // ============================================================
  //  ICÔNES POUR L'INTERFACE
  // ============================================================
  
  static const String logo = '🎓';
  static const String home = '🏠';
  static const String dashboard = '📊';
  static const String settings = '⚙️';
  static const String profile = '👤';
  static const String notifications = '🔔';
  static const String messages = '💬';
  static const String chat = '💬';
  static const String search = '🔍';
  static const String add = '➕';
  static const String edit = '✏️';
  static const String delete = '🗑️';
  static const String save = '💾';
  static const String cancel = '❌';
  static const String close = '✖️';
  static const String back = '⬅️';
  static const String next = '➡️';
  static const String refresh = '🔄';
  static const String loading = '⏳';
  static const String success = '✅';
  static const String error = '❌';
  static const String warning = '⚠️';
  static const String info = 'ℹ️';
  static const String help = '❓';
  static const String lock = '🔒';
  static const String unlock = '🔓';
  static const String star = '⭐';
  static const String favorite = '❤️';
  static const String download = '📥';
  static const String upload = '📤';
  static const String share = '📤';
  static const String link = '🔗';
  static const String calendar = '📅';
  static const String clock = '🕐';
  static const String location = '📍';
  
  // ============================================================
  //  MÉTHODE UTILITAIRE
  // ============================================================
  
  /// Récupère l'icône correspondant au nom d'une matière
  static String getSubjectIcon(String name) {
    final lowerName = name.toLowerCase().trim();
    
    // Recherche exacte
    if (subjectIcons.containsKey(lowerName)) {
      return subjectIcons[lowerName]!;
    }
    
    // Recherche partielle
    for (final entry in subjectIcons.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Si aucun match, retourner l'icône par défaut
    return '📚';
  }
  
  /// Vérifie si un texte est un emoji valide
  static bool isValidEmoji(String text) {
    // Regex pour détecter les emojis
    final emojiRegex = RegExp(
      r'^[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{1F9E0}-\u{1F9FF}\u{1FA70}-\u{1FAFF}\u{1F004}\u{1F0CF}\u{1F18E}\u{1F17A}\u{1F17F}\u{1F6A9}\u{1F3F4}\u{1F3F3}\u{1F9E6}]+$',
      unicode: true,
    );
    return emojiRegex.hasMatch(text);
  }
  
  /// Nettoie le texte pour n'obtenir que des emojis
  static String extractEmojis(String text) {
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{1F9E0}-\u{1F9FF}\u{1FA70}-\u{1FAFF}\u{1F004}\u{1F0CF}\u{1F18E}\u{1F17A}\u{1F17F}\u{1F6A9}\u{1F3F4}\u{1F3F3}\u{1F9E6}]+',
      unicode: true,
    );
    final matches = emojiRegex.allMatches(text);
    return matches.map((m) => m.group(0) ?? '').join();
  }
  
  /// Récupère l'icône par défaut pour une catégorie
  static String getDefaultIconForCategory(String category) {
    final categories = {
      'science': '🔬',
      'language': '📖',
      'humanities': '📜',
      'arts': '🎨',
      'sports': '⚽',
      'tech': '💻',
      'business': '📊',
      'education': '🎓',
      'default': '📚',
    };
    
    return categories[category] ?? categories['default']!;
  }
  
  /// Récupère une liste d'icônes populaires pour les matières
  static List<String> getPopularIcons() {
    return [
      '📐', '📖', '⚡', '🧬', '🏛️', '🗣️', '🎨', '🎵',
      '💻', '🧪', '🌍', '💭', '🧠', '📊', '⚖️', '🎓',
      '🔬', '📚', '✏️', '📝', '🧮', '🌌', '🏗️', '🎭',
      '🎨', '✏️', '💡', '🔍', '📋', '📁', '🔢', '🧩',
    ];
  }
  
  /// Récupère une liste d'emojis populaires pour la sélection
  static List<String> getPopularEmojis() {
    return const [
      '😊', '❤️', '🔥', '⭐', '👍', '💯', '🎯', '🚀',
      '🎉', '💪', '🤝', '🌈', '🌟', '✨', '💡', '🎊',
    ];
  }
  
  /// Map des noms d'icônes Material vers des emojis
  static const Map<String, String> materialToEmoji = {
    'menu_book': '📖',
    'school': '🎓',
    'science': '🔬',
    'calculate': '🧮',
    'history': '🏛️',
    'public': '🌍',
    'psychology': '🧠',
    'art_track': '🎨',
    'sports': '⚽',
    'computer': '💻',
    'code': '💻',
    'analytics': '📊',
    'business': '📋',
    'gavel': '⚖️',
    'music_note': '🎵',
    'theater_comedy': '🎭',
    'local_dining': '🍳',
    'local_florist': '🌱',
    'build': '🔧',
    'architecture': '🏗️',
  };
}