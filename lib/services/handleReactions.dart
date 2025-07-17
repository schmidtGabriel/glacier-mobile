import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

handleReactions(user) async {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  try {
    final docFriendRef = db.collection('reactions');

    var reactions =
        await docFriendRef
            .where('requested', isEqualTo: user?.uid)
            .where('user', isEqualTo: user)
            .where('status', isEqualTo: -1)
            .get();

    if (reactions.docs.isNotEmpty) {
      reactions.docs.forEach((doc) async {
        await docFriendRef.doc(doc.id).update({'status': 0});
      });
      return;
    }
  } catch (error) {
    print('Error checking existing friend invitations: $error');
    return;
  }
}
