import 'package:cloud_firestore/cloud_firestore.dart';

Future<String?> createReactionVideo(data) async {
  final db = FirebaseFirestore.instance;

  final docRef = db.collection('reaction_videos');

  final docSnapshot = await docRef.add({
    ...data,
    "created_at": FieldValue.serverTimestamp(),
  });

  if (docSnapshot.id.isNotEmpty) {
    // print('Reaction created successfully with ID: ${docSnapshot.id}');
    // docRef.doc(docSnapshot.id).update({'uuid': docSnapshot.id});
    return docSnapshot.id;
  } else {
    print('Failed to create reaction video.');
    return null;
  }
}
