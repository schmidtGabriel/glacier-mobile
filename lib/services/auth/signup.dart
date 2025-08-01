import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glacier/services/friends/updateInvitedUser.dart';
import 'package:glacier/services/user/saveFriend.dart';

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

  final existedUser =
      await docRef.where('email', isEqualTo: data['email']).limit(1).get();

  try {
    var uuid =
        existedUser.docs.isNotEmpty
            ? existedUser.docs.first.data()['uuid']
            : res.user!.uid;

    await docRef.doc(uuid).set({
      'name': data['name'],
      'phone': data['phone'],
      'email': data['email'],
      'hasAccount': data['hasAccount'] ?? false,
      'created_at': FieldValue.serverTimestamp(),
      'status': 0,
      'role': 10,
      'uuid': res.user!.uid,
    });

    print('User document created for ${res.user!.uid}');
    for (var friendEmail in data['invited_friends'] ?? []) {
      var reslt = await saveFriend(res.user!.uid, friendEmail);
    }

    await updateInvitedUser(data['email'], res.user!.uid);
    return res;
  } catch (error) {
    print('Error creating user document: $error');
    return null;
  }
}
