/// Simple User Model without json_serializable (for now)
/// Will be replaced with generated version later
class UserModel {
  final int id;
  final String username;
  final String name;
  final String? email;
  final String? profilePicture;
  final String? bio;
  final String? location;
  final DateTime createdAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int catchesCount;
  final bool? isFollowing;
  final bool? isFollower;
  final bool? isFriend;
  final bool isPremium;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    this.email,
    this.profilePicture,
    this.bio,
    this.location,
    required this.createdAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.catchesCount = 0,
    this.isFollowing,
    this.isFollower,
    this.isFriend,
    this.isPremium = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      profilePicture: json['profile_picture'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postsCount: json['posts_count'] as int? ?? 0,
      catchesCount: json['catches_count'] as int? ?? 0,
      isFollowing: json['is_following'] as bool?,
      isFollower: json['is_follower'] as bool?,
      isFriend: json['is_friend'] as bool?,
      isPremium: json['is_premium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'profile_picture': profilePicture,
      'bio': bio,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count': postsCount,
      'catches_count': catchesCount,
      'is_following': isFollowing,
      'is_follower': isFollower,
      'is_friend': isFriend,
      'is_premium': isPremium,
    };
  }
}

class FriendRequestModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final UserModel? sender;
  final UserModel? receiver;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.sender,
    this.receiver,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      sender: json['sender'] != null
          ? UserModel.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      receiver: json['receiver'] != null
          ? UserModel.fromJson(json['receiver'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sender': sender?.toJson(),
      'receiver': receiver?.toJson(),
    };
  }
}

class FriendshipModel {
  final int id;
  final int userId;
  final int friendId;
  final DateTime createdAt;
  final UserModel friend;

  FriendshipModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.createdAt,
    required this.friend,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      friendId: json['friend_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      friend: UserModel.fromJson(json['friend'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'friend_id': friendId,
      'created_at': createdAt.toIso8601String(),
      'friend': friend.toJson(),
    };
  }
}
