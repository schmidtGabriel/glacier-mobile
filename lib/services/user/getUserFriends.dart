import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glacier/helpers/parseTimeStamp.dart';
import 'package:glacier/resources/FriendResource.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/user/getUser.dart';

Future<List<FriendResource>> getUserFriends() async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('friend_invitations')
            .where('status', isEqualTo: 1)
            .where(
              Filter.or(
                Filter('requested_user', isEqualTo: uid),
                Filter('invited_user', isEqualTo: uid),
              ),
            )
            .get();

    List<FriendResource> friends = [];
    await Future.wait(
      querySnapshot.docs.map((doc) async {
        final data = doc.data();

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
