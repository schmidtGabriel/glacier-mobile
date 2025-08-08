import 'package:glacier/helpers/formatDate.dart';
import 'package:glacier/resources/UserResource.dart';

class ReactionResource {
  final String uuid;
  final String title;
  final String? description;
  final UserResource? createdBy;
  final UserResource? assignedUser;
  final String? invitedTo;
  final String status;
  final String videoUrl;
  final String videoPath;
  final String reactionUrl;
  final String reactionPath;
  final String recordUrl;
  final String recordPath;
  final int videoDuration;
  final String? createdAt;

  ReactionResource({
    required this.uuid,
    required this.title,
    this.description,
    this.createdBy,
    this.assignedUser,
    this.invitedTo,
    required this.status,
    required this.videoUrl,
    required this.videoPath,
    required this.reactionUrl,
    required this.reactionPath,
    required this.recordPath,
    required this.recordUrl,
    required this.videoDuration,
    this.createdAt,
  });

  // From JSON
  factory ReactionResource.fromJson(Map<String, dynamic> json) {
    return ReactionResource(
      uuid: json['uuid'],
      title: json['title'],
      description: json['description'],
      createdBy: UserResource.fromJson(json['created_by']),
      assignedUser:
          json['assigned_user'] != null
              ? UserResource.fromJson(json['assigned_user'])
              : null,
      invitedTo: json['invited_to'],
      status: json['status'],
      videoUrl: json['video_url'] ?? '',
      videoPath: json['video_path'] ?? '',
      reactionUrl: json['reaction_url'] ?? '',
      reactionPath: json['reaction_path'] ?? '',
      recordUrl: json['record_url'] ?? '',
      recordPath: json['record_path'] ?? '',
      videoDuration: json['video_duration'] ?? 0,
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
      'title': title,
      'description': description,
      'created_by': createdBy?.toJson(),
      'assigned_user': assignedUser?.toJson(),
      'invited_to': invitedTo,
      'status': status,
      'video_url': videoUrl,
      'video_path': videoPath,
      'reaction_url': reactionUrl,
      'reaction_path': reactionPath,
      'record_url': recordUrl,
      'record_path': recordPath,
      'video_duration': videoDuration,
      'created_at': createdAt,
    };
  }
}
