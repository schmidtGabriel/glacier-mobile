class FriendResource {
  final String uuid;
  final UserFriend requestedUser;
  final UserFriend invitedUser;
  final DateTime? createdAt;

  FriendResource({
    required this.uuid,
    required this.requestedUser,
    required this.invitedUser,
    this.createdAt,
  });

  factory FriendResource.fromJson(Map<String, dynamic> json) {
    return FriendResource(
      uuid: json['uuid'] ?? '',
      requestedUser: UserFriend.fromJson(json['requested_user'] ?? {}),
      invitedUser: UserFriend.fromJson(json['invited_user'] ?? {}),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
    );
  }

  /// Returns the friend user (not the current user)
  UserFriend getFriend(String currentUserId) {
    return invitedUser.uuid == currentUserId ? requestedUser : invitedUser;
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'requested_user': requestedUser.toJson(),
      'invited_user': invitedUser.toJson(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class UserFriend {
  final String uuid;
  final String name;
  final String email;
  final DateTime? createdAt;

  UserFriend({
    required this.uuid,
    required this.name,
    required this.email,
    this.createdAt,
  });

  factory UserFriend.fromJson(Map<String, dynamic> json) {
    return UserFriend(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'email': email,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
