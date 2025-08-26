import 'package:glacier/enums/ReactionVideoOrientation.dart';
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
  final String? videoUrl;
  final String? videoPath;
  final String? reactionUrl;
  final String? reactionPath;
  final String? recordUrl;
  final String? recordPath;
  final int? videoDuration;
  final int? delayDuration;
  final ReactionVideoOrientation videoOrientation;
  final String? createdAt;

  ReactionResource({
    required this.uuid,
    required this.title,
    this.description,
    this.createdBy,
    this.assignedUser,
    this.invitedTo,
    required this.status,
    this.videoUrl,
    this.videoPath,
    this.reactionUrl,
    this.reactionPath,
    this.recordPath,
    this.recordUrl,
    this.videoDuration,
    this.delayDuration,
    required this.videoOrientation,
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
      videoDuration: int.tryParse(json['video_duration'].toString()) ?? 0,
      delayDuration: json['delay_duration'] ?? 0,
      videoOrientation:
          json['video_orientation'] != null
              ? ReactionVideoOrientation.fromValue(json['video_orientation'])
              : ReactionVideoOrientation.portrait,
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
      'delay_duration': delayDuration,
      'video_orientation': videoOrientation.value,
      'created_at': createdAt,
    };
  }
}
