import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> updateReaction(String? uuid, Map<String, dynamic> data) async {
  if (uuid == null || uuid.isEmpty) {
    print('UUID is null or empty. Cannot update reaction.');
    return;
  }

  final db = FirebaseFirestore.instance;
  final docRef = db.collection('reactions').doc(uuid);
  final docSnapshot = await docRef.get();
  if (docSnapshot.exists) {
    await docRef.update({'uuid': uuid, ...data});
    print('Reaction updated successfully');
  } else {
    print('Document with UUID $uuid not found in reactions.');
  }
}
