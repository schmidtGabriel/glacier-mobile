import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glacier/helpers/parseTimeStamp.dart';
import 'package:glacier/resources/FriendResource.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/user/getUser.dart';

Future<List<FriendResource>> getUserFriends({bool isAll = false}) async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    Query query = FirebaseFirestore.instance.collection('friend_invitations');

    // Apply status filter only if isAll is false
    if (!isAll) {
      query = query.where('status', isEqualTo: 1);
    }

    // Apply user filter
    query = query.where(
      Filter.or(
        Filter('requested_user', isEqualTo: uid),
        Filter('invited_user', isEqualTo: uid),
      ),
    );

    final querySnapshot = await query.get();

    List<FriendResource> friends = [];
    await Future.wait(
      querySnapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return;

        UserResource? friend;
        if (data['requested_user'] != null && data['requested_user'] != uid) {
          friend = await getUser(data['requested_user']);
        } else if (data['invited_user'] != null &&
            data['invited_user'] != uid) {
          friend = await getUser(data['invited_user']);
        } else {
          friend = null; // Skip if both users are the current user
        }
        // print('Requested: ${requested?['uuid']}, Invited: ${invited?['uuid']}, Current User: $uid');

        if (friend != null) {
          friends = [
            ...friends,
            FriendResource.fromJson({
              'uuid': data['uuid'] ?? '',
              'invited_to': data['invited_to'] ?? '',
              'status': data['status'] ?? '',
              'friend': friend,
              'created_at': formatTimestamp(data['created_at']),
            }),
          ];
        }
      }).toList(),
    );
    return friends;
  } catch (e) {
    print('Error fetching user friends: $e');
    return [];
  }
}
