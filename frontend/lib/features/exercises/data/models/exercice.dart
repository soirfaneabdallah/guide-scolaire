// frontend/lib/features/exercices/data/models/exercice.dart
import 'package:flutter/material.dart'; 
enum ExerciceDifficulty { easy, medium, hard }
enum ExerciceStatus { not_started, in_progress, completed, failed }

class Exercice {
  final String id;
  final String title;
  final String subject;      // Maths, Français, etc.
  final String subjectSlug;
  final String description;
  final String question;
  final String? correction;
  final List<String>? hints;
  final ExerciceDifficulty difficulty;
  final String level;        // 6ème, 5ème, 4ème, 3ème, Seconde, Première, Terminale
  final int points;
  final int timeLimit;       // en secondes
  final bool isCompleted;
  final double? successRate;
  final DateTime? lastAttempt;
  final ExerciceStatus status;

  Exercice({
    required this.id,
    required this.title,
    required this.subject,
    required this.subjectSlug,
    required this.description,
    required this.question,
    this.correction,
    this.hints,
    required this.difficulty,
    required this.level,
    required this.points,
    required this.timeLimit,
    this.isCompleted = false,
    this.successRate,
    this.lastAttempt,
    this.status = ExerciceStatus.not_started,
  });

  factory Exercice.fromJson(Map<String, dynamic> json) {
    return Exercice(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      subjectSlug: json['subject_slug'] ?? '',
      description: json['description'] ?? '',
      question: json['question'] ?? '',
      correction: json['correction'],
      hints: json['hints'] != null ? List<String>.from(json['hints']) : null,
      difficulty: ExerciceDifficulty.values.firstWhere(
        (d) => d.toString().split('.').last == json['difficulty'],
        orElse: () => ExerciceDifficulty.medium,
      ),
      level: json['level'] ?? '',
      points: json['points'] ?? 0,
      timeLimit: json['time_limit'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      successRate: json['success_rate']?.toDouble(),
      lastAttempt: json['last_attempt'] != null
          ? DateTime.parse(json['last_attempt'])
          : null,
      status: ExerciceStatus.values.firstWhere(
        (s) => s.toString().split('.').last == json['status'],
        orElse: () => ExerciceStatus.not_started,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'subject_slug': subjectSlug,
      'description': description,
      'question': question,
      'correction': correction,
      'hints': hints,
      'difficulty': difficulty.toString().split('.').last,
      'level': level,
      'points': points,
      'time_limit': timeLimit,
      'is_completed': isCompleted,
      'success_rate': successRate,
      'last_attempt': lastAttempt?.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }

  Exercice copyWith({
    String? id,
    String? title,
    String? subject,
    String? subjectSlug,
    String? description,
    String? question,
    String? correction,
    List<String>? hints,
    ExerciceDifficulty? difficulty,
    String? level,
    int? points,
    int? timeLimit,
    bool? isCompleted,
    double? successRate,
    DateTime? lastAttempt,
    ExerciceStatus? status,
  }) {
    return Exercice(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      subjectSlug: subjectSlug ?? this.subjectSlug,
      description: description ?? this.description,
      question: question ?? this.question,
      correction: correction ?? this.correction,
      hints: hints ?? this.hints,
      difficulty: difficulty ?? this.difficulty,
      level: level ?? this.level,
      points: points ?? this.points,
      timeLimit: timeLimit ?? this.timeLimit,
      isCompleted: isCompleted ?? this.isCompleted,
      successRate: successRate ?? this.successRate,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      status: status ?? this.status,
    );
  }

  String get difficultyLabel {
    switch (difficulty) {
      case ExerciceDifficulty.easy:
        return 'Facile';
      case ExerciceDifficulty.medium:
        return 'Moyen';
      case ExerciceDifficulty.hard:
        return 'Difficile';
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case ExerciceDifficulty.easy:
        return Colors.green;
      case ExerciceDifficulty.medium:
        return Colors.orange;
      case ExerciceDifficulty.hard:
        return Colors.red;
    }
  }

  String get statusLabel {
    switch (status) {
      case ExerciceStatus.not_started:
        return 'Non commencé';
      case ExerciceStatus.in_progress:
        return 'En cours';
      case ExerciceStatus.completed:
        return 'Terminé';
      case ExerciceStatus.failed:
        return 'Échoué';
    }
  }

  Color get statusColor {
    switch (status) {
      case ExerciceStatus.not_started:
        return Colors.grey;
      case ExerciceStatus.in_progress:
        return Colors.blue;
      case ExerciceStatus.completed:
        return Colors.green;
      case ExerciceStatus.failed:
        return Colors.red;
    }
  }
}