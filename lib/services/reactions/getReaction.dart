import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glacier/helpers/parseTimeStamp.dart';
import 'package:glacier/services/reactions/listReactions.dart';
import 'package:glacier/services/user/getUser.dart';

Future<Map<String, dynamic>?> getReaction(String uuid) async {
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
      final recordUrl = await handleRecord(data);
      return {
        ...data,
        'created_at': formatTimestamp(data['created_at']),
        'due_date': formatTimestamp(data['due_date']),
        'requested':
            data['requested'] != null ? await getUser(data['requested']) : null,
        'user': data['user'] != null ? await getUser(data['user']) : null,
        'url': videoUrl,
        'recordedUrl': recordUrl,
      };
    }
  } catch (e) {
    print('Error fetching reaction: $e');
    return null;
  }
  return null;
}
