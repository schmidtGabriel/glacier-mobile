import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> logReaction(String uuid, data) async {
  try {
    final reactionData = {
      'uuid': uuid ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'data': data.toString(),
    };

    await FirebaseFirestore.instance
        .collection('reaction_logs')
        .add(reactionData);
    print('Reaction logged successfully: $uuid');
  } catch (e) {
    print('Error logging reaction: $e');
  }
}
