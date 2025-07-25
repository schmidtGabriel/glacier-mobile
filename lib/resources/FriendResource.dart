import 'package:glacier/resources/UserResource.dart';

class FriendResource {
  final String uuid;
  final UserResource? requestedUser;
  final UserResource? invitedUser;
  final String? invitedTo;
  final String? createdAt;
  final int? status;
  final bool? isRequested;
  final UserResource? friend;

  FriendResource({
    required this.uuid,
    this.requestedUser,
    this.invitedUser,
    this.invitedTo,
    this.createdAt,
    this.status,
    this.isRequested,
    this.friend,
  });

  factory FriendResource.fromJson(Map<String, dynamic> json) {
    return FriendResource(
      uuid: json['uuid'] ?? '',
      status: json['status'],
      invitedTo: json['invited_to'] ?? '',
      isRequested: json['isRequested'] ?? false,
      createdAt: json['created_at'],
      friend: json['friend'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'requested_user': requestedUser?.toJson(),
      'invited_user': invitedUser?.toJson(),
      'invited_to': invitedTo,
      'isRequested': isRequested,
      'friend': friend?.toJson(),
      'created_at': createdAt,
      'status': status,
    };
  }
}
