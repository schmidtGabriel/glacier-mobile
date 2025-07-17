import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glacier/services/handleReactions.dart';

Future<bool> updateFriendRequest(int status, String uuid) async {
  try {
    if (status != -1 && status != 1) {
      throw ArgumentError('Invalid status: $status. Must be -1 or 1.');
    }
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    bool requested;
    final docRef = db.collection('friend_invitations').doc(uuid);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await docRef.update({'invited_user': user?.uid, 'status': status});

      await handleReactions(docSnapshot.data()?['requested_user']);

      requested = true; // or any appropriate value to indicate success
      print('Friend Inviting updated successfully');
    } else {
      requested = false;
      print('Document with UUID $uuid not found in users.');
    }

    return requested;
  } catch (e) {
    print('Error fetching user friends: $e');
    return false;
  }
}
