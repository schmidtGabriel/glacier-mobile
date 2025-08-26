import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glacier/enums/ReactionVideoOrientation.dart';
import 'package:glacier/helpers/parseTimeStamp.dart';
import 'package:glacier/resources/ReactionResource.dart';
import 'package:glacier/services/user/getUser.dart';

Future<List<ReactionResource>> listReactions({
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
              Filter('status', isEqualTo: '10'),
            ),
          );
    } else {
      query = query
          .where('user', isEqualTo: userId)
          .where(
            Filter.or(
              Filter('status', isEqualTo: '0'),
              Filter('status', isEqualTo: '1'),
              Filter('status', isEqualTo: '10'),
            ),
          );
    }

    final querySnapshot = await query.get();

    // Use async map and wait for all futures
    final results = await Future.wait(
      querySnapshot.docs.map((doc) async {
        try {
          final data = doc.data();
          return ReactionResource(
            uuid: data['uuid'] ?? '',
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            createdAt:
                data['created_at'] != null
                    ? formatTimestamp(data['created_at'])
                    : null,
            createdBy:
                data['requested'] != null
                    ? await getUser(data['requested'])
                    : null,
            assignedUser:
                data['user'] != null ? await getUser(data['user']) : null,
            status: data['status'] ?? '',
            videoDuration: data['video_duration'] ?? 0,
            videoOrientation:
                data['video_orientation'] != null
                    ? ReactionVideoOrientation.fromValue(
                      data['video_orientation'],
                    )
                    : ReactionVideoOrientation.portrait,
          );
        } catch (e) {
          print('Error processing reaction document ${doc.id}: $e');
          // Return null for failed documents, will be filtered out
          return null;
        }
      }),
    );

    // Filter out null values and return only successful ReactionResource objects
    final filteredResults =
        results
            .where((reaction) => reaction != null)
            .cast<ReactionResource>()
            .toList();

    // Sort by created_at in descending order (newest first)
    filteredResults.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return filteredResults;
  } catch (e) {
    print('Error fetching reactions: $e');
    return [];
  }
}
