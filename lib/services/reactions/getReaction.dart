import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glacier/enums/ReactionVideoOrientation.dart';
import 'package:glacier/helpers/parseTimeStamp.dart';
import 'package:glacier/resources/ReactionResource.dart';
import 'package:glacier/services/reactions/getReactionVideos.dart';
import 'package:glacier/services/user/getUser.dart';

Future<ReactionResource?> getReaction(String uuid) async {
  try {
    if (uuid.isEmpty) {
      print('UUID is empty, cannot fetch reaction.');
      return null;
    }

    final doc =
        await FirebaseFirestore.instance
            .collection('reactions')
            .doc(uuid)
            .get();

    if (doc.exists) {
      final data = doc.data();
      if (data == null) {
        print('No data found for UUID: $uuid');
        return null;
      }

      final videoUrl = await handleVideo(data);
      final reactionUrl = await handleReaction(data);
      final recordUrl = await handleRecord(data);

      return ReactionResource(
        uuid: uuid,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        createdBy: await getUser(data['requested']),
        assignedUser: await getUser(data['user']),
        invitedTo: data['invited_to'],
        status: data['status'] ?? '',
        videoUrl: videoUrl,
        videoPath: data['video_path'] ?? '',
        reactionUrl: reactionUrl,
        reactionPath: data['reaction_path'] ?? '',
        recordUrl: recordUrl,
        recordPath: data['record_path'] ?? '',
        videoDuration: data['video_duration'] ?? 0,
        delayDuration: data['delay_duration'] ?? 0,
        videoOrientation:
            data['video_orientation'] != null
                ? ReactionVideoOrientation.fromValue(data['video_orientation'])
                : ReactionVideoOrientation.portrait,
        createdAt: formatTimestamp(data['created_at']),
      );
    }
    return null;
  } catch (e) {
    print('Error fetching reaction: $e');
    return null;
  }
  return null;
}
