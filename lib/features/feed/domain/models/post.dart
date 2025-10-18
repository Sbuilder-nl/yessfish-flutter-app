class Post {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final String? location;
  final String createdAt;
  final String userName;
  final String? username;
  final String? profilePhoto;
  final int likesCount;
  final int commentsCount;
  final String timeAgo;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    this.location,
    required this.createdAt,
    required this.userName,
    this.username,
    this.profilePhoto,
    required this.likesCount,
    required this.commentsCount,
    required this.timeAgo,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      location: json['location'],
      createdAt: json['created_at'] ?? '',
      userName: json['user_name'] ?? 'Onbekende gebruiker',
      username: json['username'],
      profilePhoto: json['profile_photo'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      timeAgo: json['time_ago'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'location': location,
      'created_at': createdAt,
      'user_name': userName,
      'username': username,
      'profile_photo': profilePhoto,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'time_ago': timeAgo,
    };
  }
}
