import 'package:cloud_firestore/cloud_firestore.dart';

handleInvitations(email, uid) async {
  final db = FirebaseFirestore.instance;
  final docFriendRef = db.collection('friend_invitations');

  try {
    var friends =
        await docFriendRef.where('invited_email', isEqualTo: email).get();

    if (friends.docs.isNotEmpty) {
      friends.docs.forEach((doc) async {
        if (doc['status'] == 0) {
          await docFriendRef.doc(doc.id).update({'invited_user': uid});
        }
      });
      return;
    }
  } catch (error) {
    print('Error checking existing friend invitations: $error');
    return;
  }
}
