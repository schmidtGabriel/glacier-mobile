class FriendResource {
  final String uuid;
  final UserFriend? requestedUser;
  final UserFriend? invitedUser;
  final String? createdAt;
  final UserFriend? friend;

  FriendResource({
    required this.uuid,
    this.requestedUser,
    this.invitedUser,
    this.createdAt,
    this.friend,
  });

  factory FriendResource.fromJson(Map<String, dynamic> json) {
    return FriendResource(
      uuid: json['uuid'] ?? '',
      // requestedUser: UserFriend.fromJson(json['requested_user'] ?? {}),
      // invitedUser: UserFriend.fromJson(json['invited_user'] ?? {}),
      createdAt: json['created_at'],
      friend:
          json['friend'] != null ? UserFriend.fromJson(json['friend']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'requested_user': requestedUser?.toJson(),
      'invited_user': invitedUser?.toJson(),
      'friend': friend?.toJson(),
      'created_at': createdAt,
    };
  }
}

class UserFriend {
  final String uuid;
  final String name;
  final String email;
  final String profilePic;
  final String? createdAt;

  UserFriend({
    required this.uuid,
    required this.name,
    required this.email,
    this.profilePic = '',
    this.createdAt,
  });

  factory UserFriend.fromJson(Map<String, dynamic> json) {
    return UserFriend(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePic: json['profile_picture'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'email': email,
      'profile_picture': profilePic,
    };
  }
}
