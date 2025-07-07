import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> cancelReaction(uuid) async {
  final db = FirebaseFirestore.instance;

  final docRef = db.collection('reactions').doc(uuid);
  final docSnapshot = await docRef.get();
  if (docSnapshot.exists) {
    await docRef.update({'status': '-10'});
    print('Reaction updated successfully');
  } else {
    print('Document with UUID $uuid not found in reactions.');
  }
}
