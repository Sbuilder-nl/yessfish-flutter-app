import 'package:json_annotation/json_annotation.dart';
import '../../../friends/data/models/user_model.dart';

part 'post_model.g.dart';

@JsonSerializable()
class PostModel {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String content;
  final String? image;
  @JsonKey(name: 'likes_count')
  final int likesCount;
  @JsonKey(name: 'comments_count')
  final int commentsCount;
  @JsonKey(name: 'shares_count')
  final int sharesCount;
  @JsonKey(name: 'is_liked')
  final bool isLiked;
  @JsonKey(name: 'is_saved')
  final bool isSaved;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  // Related data
  final UserModel user;
  final List<CommentModel>? comments;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.image,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.isLiked,
    this.isSaved = false,
    required this.createdAt,
    this.updatedAt,
    required this.user,
    this.comments,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);

  Map<String, dynamic> toJson() => _$PostModelToJson(this);

  PostModel copyWith({
    int? id,
    int? userId,
    String? content,
    String? image,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLiked,
    bool? isSaved,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? user,
    List<CommentModel>? comments,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      image: image ?? this.image,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      comments: comments ?? this.comments,
    );
  }
}

@JsonSerializable()
class CommentModel {
  final int id;
  @JsonKey(name: 'post_id')
  final int postId;
  @JsonKey(name: 'user_id')
  final int userId;
  final String content;
  @JsonKey(name: 'likes_count')
  final int likesCount;
  @JsonKey(name: 'is_liked')
  final bool isLiked;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  // Related data
  final UserModel user;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.likesCount,
    required this.isLiked,
    required this.createdAt,
    required this.user,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommentModelToJson(this);
}

@JsonSerializable()
class CreatePostRequest {
  final String content;
  final String? image;

  CreatePostRequest({
    required this.content,
    this.image,
  });

  Map<String, dynamic> toJson() => _$CreatePostRequestToJson(this);
}

@JsonSerializable()
class CreateCommentRequest {
  final String content;

  CreateCommentRequest({required this.content});

  Map<String, dynamic> toJson() => _$CreateCommentRequestToJson(this);
}
