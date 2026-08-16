// frontend/lib/features/library/models/book_comment.dart

class BookComment {
  final int id;
  final String content;
  final int bookId;
  final int userId;
  final String userName;
  final String? userAvatar;
  final int? parentId;
  final bool isEdited;
  final int likesCount;
  final bool isLiked;  // ✅ Ajouter ce champ
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<BookComment> replies;

  BookComment({
    required this.id,
    required this.content,
    this.bookId = 0,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.parentId,
    this.isEdited = false,
    this.likesCount = 0,
    this.isLiked = false,  // ✅ Ajouter avec valeur par défaut
    required this.createdAt,
    this.updatedAt,
    this.replies = const [],
  });

  factory BookComment.fromJson(Map<String, dynamic> json) {
    return BookComment(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      bookId: json['book_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? 'Anonyme',
      userAvatar: json['user_avatar'],
      parentId: json['parent_id'],
      isEdited: json['is_edited'] ?? false,
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,  // ✅ Ajouter
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      replies: (json['replies'] as List?)
          ?.map((r) => BookComment.fromJson(r))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'parent_id': parentId,
      'is_liked': isLiked,  // ✅ Ajouter
    };
  }

  BookComment copyWith({
    int? id,
    String? content,
    int? bookId,
    int? userId,
    String? userName,
    String? userAvatar,
    int? parentId,
    bool? isEdited,
    int? likesCount,
    bool? isLiked,  // ✅ Ajouter
    DateTime? createdAt,
    DateTime? updatedAt,
    List<BookComment>? replies,
  }) {
    return BookComment(
      id: id ?? this.id,
      content: content ?? this.content,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      parentId: parentId ?? this.parentId,
      isEdited: isEdited ?? this.isEdited,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,  // ✅ Ajouter
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replies: replies ?? this.replies,
    );
  }
}