import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glacier/services/user/getUser.dart';

Future<List> getUserFriends() async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    print('Fetching friends for user: $uid');
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('friend_invitations')
            .where(
              Filter.or(
                Filter('requested_user', isEqualTo: uid),
                Filter('invited_user', isEqualTo: uid),
              ),
            )
            .get();

    List requested = await Future.wait(
      querySnapshot.docs.map((doc) async {
        final data = doc.data();
        return {
          'uuid': data['uuid'] ?? '',
          'requested_user':
              data['requested_user'] != null
                  ? await getUser(data['requested_user'])
                  : null,
          'invited_user':
              data['invited_user'] != null
                  ? await getUser(data['invited_user'])
                  : null,
          'invited_email': data['invited_email'] ?? '',
          'status': data['status'] ?? '',
          'created_at': data['created_at']?.toDate().toIso8601String(),
        };
      }).toList(),
    );

    return requested;
  } catch (e) {
    print('Error fetching user friends: $e');
    return [];
  }
}
