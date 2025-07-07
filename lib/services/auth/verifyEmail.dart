import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

verifyEmailAccount(email) async {
  try {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      var user = querySnapshot.docs.first.data();

      if (user['hasAccount'] == true) {
        return true;
      } else {
        return false;
      }
    }

    return false;
  } on FirebaseAuthException catch (e) {
    print('Error: ${e.code}');
    return false;
  }
}
