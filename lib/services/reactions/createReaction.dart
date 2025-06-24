import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<String?> createReaction(data) async {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  final docRef = db.collection('reactions');

  final docSnapshot = await docRef.add(data);
  if (docSnapshot.id.isNotEmpty) {
    print('Reaction created successfully with ID: ${docSnapshot.id}');
    docRef.doc(docSnapshot.id).update({
      'created_at': FieldValue.serverTimestamp(),
      'status': '0', // Assuming '0' means pending
      'uuid': docSnapshot.id,
      'requested': user?.uid ?? '',
    });
    return docSnapshot.id;
  } else {
    print('Failed to create reaction.');
    return null;
  }
}
