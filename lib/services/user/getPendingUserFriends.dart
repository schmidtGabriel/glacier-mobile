import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glacier/helpers/parseTimeStamp.dart';
import 'package:glacier/services/user/getUser.dart';

Future<List> getPendingUserFriends() async {
  try {
    final email = FirebaseAuth.instance.currentUser?.email;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (email == null) return [];
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('friend_invitations')
            .where('status', isEqualTo: 0)
            .where(
              Filter.or(
                Filter('requested_user', isEqualTo: userId),
                Filter('invited_email', isEqualTo: email),
                Filter('invited_user', isEqualTo: userId),
              ),
            )
            .get();

    List pendingUsers = [];
    await Future.wait(
      querySnapshot.docs.map((doc) async {
        final data = doc.data();

        final requested =
            data['requested_user'] != null
                ? await getUser(data['requested_user'])
                : null;

        final invited =
            data['invited_user'] != null
                ? await getUser(data['invited_user'])
                : null;
        // print('invited $invited');
        // print('requested $requested');

        if (requested != null) {
          pendingUsers = [
            ...pendingUsers,
            {
              'uuid': data['uuid'] ?? '',
              'requested_user': requested,
              'invited_user': invited,
              'invited_email': data['invited_email'] ?? '',
              'status': data['status'] ?? '',
              'created_at': formatTimestamp(data['created_at']),
              'isRequested': userId == requested['uuid'],
            },
          ];
        }
      }).toList(),
    );
    // print('Pending: $pendingUsers');
    return pendingUsers;
  } catch (e) {
    print('Error fetching user friends: $e');
    return [];
  }
}
