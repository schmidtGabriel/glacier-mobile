import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glacier/helpers/parseTimeStamp.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:glacier/services/user/getUser.dart';

Future<String> handleRecord(data) async {
  try {
    if (data['recorded_video'] != null || data['recorded_video'].isNotEmpty) {
      final service = FirebaseStorageService();
      String res = await service.getDownloadUrl(data['recorded_video']);

      if (res.isNotEmpty) {
        return res;
      } else {
        return '';
      }
    } else {
      return '';
    }
  } catch (e) {
    // print('Error fetching video URL: $e');
    return '';
  }
}

Future<String> handleVideo(data) async {
  try {
    if (data['video'] != null || data['video'].isNotEmpty) {
      final service = FirebaseStorageService();
      if (data['type_video'] == '3') {
        String res = await service.getDownloadUrl(data['video']);
        return res;
      } else {
        return data['video'] ?? '';
      }
    } else {
      return '';
    }
  } catch (e) {
    // print('Error fetching video URL: $e');
    return '';
  }
}

Future<List> listReactions({
  required String userId,
  bool isSent = false,
}) async {
  try {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'reactions',
    );
    if (isSent) {
      query = query
          .where('requested', isEqualTo: userId)
          .where(
            Filter.or(
              Filter('status', isEqualTo: '0'),
              Filter('status', isEqualTo: '1'),
            ),
          );
    } else {
      query = query
          .where('user', isEqualTo: userId)
          .where(
            Filter.or(
              Filter('status', isEqualTo: '0'),
              Filter('status', isEqualTo: '1'),
            ),
          );
    }

    final querySnapshot = await query.get();

    // Use async map and wait for all futures
    final res = await Future.wait(
      querySnapshot.docs.map((doc) async {
        final data = doc.data();
        final videoUrl = await handleVideo(data);
        final recordUrl = await handleRecord(data);
        return {
          ...data,
          'created_at': formatTimestamp(data['created_at']),
          'due_date': formatTimestamp(data['due_date']),
          'requested':
              data['requested'] != null
                  ? await getUser(data['requested'])
                  : null,
          'user': data['user'] != null ? await getUser(data['user']) : null,
          'url': videoUrl,
          'recordedUrl': recordUrl,
        };
      }),
    );

    return res;
  } catch (e) {
    print('Error fetching reactions: $e');
    return [];
  }
}
