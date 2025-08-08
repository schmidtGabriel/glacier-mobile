import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> updateReaction(data) async {
  final db = FirebaseFirestore.instance;
  final docRef = db.collection('reactions').doc(data['uuid']);
  final docSnapshot = await docRef.get();
  if (docSnapshot.exists) {
    await docRef.update(data);
    print('Reaction updated successfully');
  } else {
    print('Document with UUID ${data.uuid} not found in reactions.');
  }
}
