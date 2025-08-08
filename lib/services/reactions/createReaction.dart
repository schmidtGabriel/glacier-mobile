import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<String?> createReaction(data) async {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  final docRef = db.collection('reactions');

  final status = (data['user'] != null) ? '0' : '-1';

  final docSnapshot = await docRef.add({
    ...data,
    "requested": user?.uid ?? '',
    "status": status,
    "created_at": FieldValue.serverTimestamp(),
  });

  if (docSnapshot.id.isNotEmpty) {
    // print('Reaction created successfully with ID: ${docSnapshot.id}');
    // docRef.doc(docSnapshot.id).update({'uuid': docSnapshot.id});
    return docSnapshot.id;
  } else {
    print('Failed to create reaction.');
    return null;
  }
}
