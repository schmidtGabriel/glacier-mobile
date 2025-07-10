class UserResource {
  final String uuid;
  final String name;
  final String email;
  final String profilePic;
  final DateTime? createdAt;

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
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'email': email,
      'profile_picture': profilePic,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
