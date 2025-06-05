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
            .where('requested_user', isEqualTo: uid)
            .where('status', isEqualTo: '1')
            .where('invited_user', isNotEqualTo: null)
            .get();

    final querySnapshot2 =
        await FirebaseFirestore.instance
            .collection('friend_invitations')
            .where('status', isEqualTo: '1')
            .where('invited_user', isEqualTo: uid)
            .get();

    List requested = await Future.wait(
      querySnapshot.docs.map((doc) async {
        final data = doc.data();
        return {
          'uuid': data['uuid'],
          'requested_user': await getUser(data['requested_user']),
          'invited_user': await getUser(data['invited_user']),
          'created_at': data['created_at']?.toDate().toIso8601String(),
        };
      }).toList(),
    );

    List invited = await Future.wait(
      querySnapshot2.docs.map((doc) async {
        final data = doc.data();
        return {
          'uuid': data['uuid'],
          'requested_user': await getUser(data['requested_user']),
          'invited_user': await getUser(data['invited_user']),
          'created_at': data['created_at']?.toDate().toIso8601String(),
        };
      }).toList(),
    );

    return [...requested, ...invited];
  } catch (e) {
    print('Error fetching user friends: $e');
    return [];
  }
}
