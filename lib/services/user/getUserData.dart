import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glacier/helpers/saveUserInfo.dart';

Future<Map<String, dynamic>?> getUserData() async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return null;

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('uuid', isEqualTo: uid)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      await saveUserInfo(querySnapshot.docs.first.data());

      return querySnapshot.docs.first.data();
    } else {
      return null;
    }
  } catch (e) {
    print('Error fetching user data: $e');
    return null;
  }
}
