import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glacier/services/user/saveFriend.dart';

handleInvitations(email, uid) async {
  final db = FirebaseFirestore.instance;
  final docFriendRef = db.collection('friend_invitations');

  try {
    var friends =
        await docFriendRef.where('friend_email', isEqualTo: email).get();

    if (friends.docs.isNotEmpty) {
      friends.docs.forEach((doc) async {
        if (doc['status'] == 0) {
          await docFriendRef.doc(doc.id).update({
            'invited_user': uid,
            'status': 1,
          });
        }
      });
      return;
    }
  } catch (error) {
    print('Error checking existing friend invitations: $error');
    return;
  }
}

signup(data) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  var res = await auth.createUserWithEmailAndPassword(
    email: data['email'],
    password: data['password'],
  );

  if (res.user == null) {
    print('Signup failed: ${res.toString()}');
    return null;
  }

  final docRef = db.collection('users');

  try {
    await docRef.doc(res.user!.uid).set({
      'name': data['name'],
      'phone': data['phone'],
      'email': data['email'],
      'created_at': FieldValue.serverTimestamp(),
      'status': 0,
      'role': 10,
      'uuid': res.user!.uid,
    });
    print('User document created for ${res.user!.uid}');
    for (var friendEmail in data['invited_friends'] ?? []) {
      var reslt = await saveFriend(res.user!.uid, friendEmail);
    }

    await handleInvitations(data['email'], res.user!.uid);
    return res;
  } catch (error) {
    print('Error creating user document: $error');
    return null;
  }
}
