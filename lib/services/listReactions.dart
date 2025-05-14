import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glacier/helpers/ParseTimeStamp.dart';

Future<List> listReactions({required String userId}) async {
  try {
    final db = FirebaseFirestore.instance;

    final querySnapshot =
        await db.collection('reactions').where('user', isEqualTo: userId).get();

    List res =
        querySnapshot.docs
            .map(
              (doc) => {
                ...doc.data(),
                'created_at': formatTimestamp(doc.data()['created_at']),
                'due_date': formatTimestamp(doc.data()['due_date']),
              },
            )
            .toList();
    print(res);
    return res;
  } catch (e) {
    print('Error fetching reactions: $e');
    return [];
  }
}
