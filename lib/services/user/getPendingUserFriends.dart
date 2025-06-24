import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glacier/services/user/getUser.dart';

Future<List> getPendingUserFriends() async {
  try {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return [];
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('friend_invitations')
            .where(Filter('invited_email', isEqualTo: email))
            .where(Filter('status', isEqualTo: 0))
            .get();

    List requested = await Future.wait(
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

        if (requested == null) {
          print('No valid users found for invitation: ${data['uuid']}');
          return null;
        }

        return {
          'uuid': data['uuid'] ?? '',
          'requested_user': requested,
          'invited_user': invited,
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
