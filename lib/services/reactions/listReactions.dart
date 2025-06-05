import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glacier/helpers/ParseTimeStamp.dart';
import 'package:glacier/services/FirebaseStorageService.dart';

Future<String> handleVideo(data) async {
  try {
    final service = FirebaseStorageService();
    if (data['type_video'] == '3') {
      String res = await service.getDownloadUrl(data['url']);
      return res;
    } else {
      return data['url'] ?? '';
    }
  } catch (e) {
    print('Error fetching video URL: $e');
    return '';
  }
}

Future<List> listReactions({required String userId}) async {
  try {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('reactions')
            .where('user', isEqualTo: userId)
            .get();

    // Use async map and wait for all futures
    final res = await Future.wait(
      querySnapshot.docs.map((doc) async {
        final data = doc.data();
        final videoUrl = await handleVideo(data);
        return {
          ...data,
          'created_at': formatTimestamp(data['created_at']),
          'due_date': formatTimestamp(data['due_date']),
          'url': videoUrl,
        };
      }),
    );

    return res;
  } catch (e) {
    print('Error fetching reactions: $e');
    return [];
  }
}
