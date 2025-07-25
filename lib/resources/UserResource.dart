import 'package:glacier/helpers/formatDate.dart';

class UserResource {
  final String uuid;
  final String name;
  final String email;
  final String profilePic;
  final String? createdAt;

  UserResource({
    required this.uuid,
    required this.name,
    required this.email,
    this.profilePic = '',
    this.createdAt,
  });

  // From JSON
  factory UserResource.fromJson(Map<String, dynamic> json) {
    return UserResource(
      uuid: json['uuid'],
      name: json['name'],
      email: json['email'],
      profilePic: json['profile_picture'] ?? '',
      createdAt: formatDate(
        json['created_at'] is String
            ? json['created_at']
            : json['created_at']?.toString(),
      ),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'email': email,
      'profile_picture': profilePic,
      'created_at': createdAt,
    };
  }
}
