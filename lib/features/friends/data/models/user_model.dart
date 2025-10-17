import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final int id;
  final String username;
  final String name;
  final String? email;
  @JsonKey(name: 'profile_picture')
  final String? profilePicture;
  final String? bio;
  final String? location;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'followers_count')
  final int followersCount;
  @JsonKey(name: 'following_count')
  final int followingCount;
  @JsonKey(name: 'posts_count')
  final int postsCount;
  @JsonKey(name: 'catches_count')
  final int catchesCount;
  @JsonKey(name: 'is_following')
  final bool? isFollowing;
  @JsonKey(name: 'is_follower')
  final bool? isFollower;
  @JsonKey(name: 'is_friend')
  final bool? isFriend;
  @JsonKey(name: 'is_premium')
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
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.catchesCount,
    this.isFollowing,
    this.isFollower,
    this.isFriend,
    this.isPremium = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

@JsonSerializable()
class FriendRequestModel {
  final int id;
  @JsonKey(name: 'sender_id')
  final int senderId;
  @JsonKey(name: 'receiver_id')
  final int receiverId;
  final String status; // pending, accepted, rejected
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  // Relationship data
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

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$FriendRequestModelToJson(this);
}

@JsonSerializable()
class FriendshipModel {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'friend_id')
  final int friendId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  // Friend user data
  final UserModel friend;

  FriendshipModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.createdAt,
    required this.friend,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) =>
      _$FriendshipModelFromJson(json);

  Map<String, dynamic> toJson() => _$FriendshipModelToJson(this);
}
