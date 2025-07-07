import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glacier/services/user/getUser.dart';

Future<List> getUserFriends() async {
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

    List friends = [];
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

        if (requested != null && invited != null) {
          friends = [
            ...friends,
            {
              'uuid': data['uuid'] ?? '',
              'requested_user': requested,
              'invited_user': invited,
              'invited_email': data['invited_email'] ?? '',
              'status': data['status'] ?? '',
              'created_at': data['created_at']?.toDate().toIso8601String(),
            },
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
