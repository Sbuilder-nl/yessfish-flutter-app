class UserProfile {
  final String id;
  final String name;
  final String? username;
  final String? email;
  final String? profilePhoto;
  final String? bio;
  final int catchesCount;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final String createdAt;

  UserProfile({
    required this.id,
    required this.name,
    this.username,
    this.email,
    this.profilePhoto,
    this.bio,
    required this.catchesCount,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      name: json['name'] ?? 'Onbekende gebruiker',
      username: json['username'],
      email: json['email'],
      profilePhoto: json['profile_photo'],
      bio: json['bio'],
      catchesCount: json['catches_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}
