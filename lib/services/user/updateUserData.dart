import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glacier/helpers/saveUserInfo.dart';

Future<Map<String, dynamic>?> updateUserData(data) async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await docRef.update(data);

      final updatedDoc = await docRef.get();

      await saveUserInfo(updatedDoc.data());

      return updatedDoc.data();
    } else {
      return null;
    }
  } catch (e) {
    print('Error fetching user data: $e');
    return null;
  }
}
