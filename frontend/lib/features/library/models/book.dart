// frontend/lib/features/library/models/book.dart

class Book {
  final int id;
  final String title;
  final String description;
  final String author;
  final String? coverImage;
  final String? fileUrl;
  final String? level;
  final int? subjectId;
  final String? subject;
  final int userId;
  final String userName;
  final bool isPublic;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final double averageRating;
  final DateTime createdAt;
  final DateTime? updatedAt;
  bool isLiked;

  Book({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    this.coverImage,
    this.fileUrl,
    this.level,
    this.subjectId,
    this.subject,
    required this.userId,
    required this.userName,
    this.isPublic = true,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.averageRating = 0.0,
    required this.createdAt,
    this.updatedAt,
    this.isLiked = false,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      author: json['author'],
      coverImage: json['cover_image'],
      fileUrl: json['file_url'],
      level: json['level'],
      subjectId: json['subject_id'],
      subject: json['subject'],
      userId: json['user_id'],
      userName: json['user_name'],
      isPublic: json['is_public'] ?? true,
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      averageRating: json['average_rating'] ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isLiked: json['is_liked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'author': author,
      'cover_image': coverImage,
      'file_url': fileUrl,
      'level': level,
      'subject_id': subjectId,
      'is_public': isPublic,
    };
  }

  Book copyWith({
    int? id,
    String? title,
    String? description,
    String? author,
    String? coverImage,
    String? fileUrl,
    String? level,
    int? subjectId,
    String? subject,
    int? userId,
    String? userName,
    bool? isPublic,
    int? viewsCount,
    int? likesCount,
    int? commentsCount,
    double? averageRating,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLiked,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      coverImage: coverImage ?? this.coverImage,
      fileUrl: fileUrl ?? this.fileUrl,
      level: level ?? this.level,
      subjectId: subjectId ?? this.subjectId,
      subject: subject ?? this.subject,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      isPublic: isPublic ?? this.isPublic,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      averageRating: averageRating ?? this.averageRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}