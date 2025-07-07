import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, dynamic>?> getUser(String uuid) async {
  try {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('uuid', isEqualTo: uuid)
            .limit(1)
            .get();
    if (querySnapshot.docs.isNotEmpty) {
      return {
        'uuid': querySnapshot.docs.first.data()['uuid'],
        'name': querySnapshot.docs.first.data()['name'],
        'email': querySnapshot.docs.first.data()['email'],
        'created_at':
            querySnapshot.docs.first
                .data()['created_at']
                ?.toDate()
                .toIso8601String(),
      };
    } else {
      return null;
    }
  } catch (e) {
    print('Error fetching user data: $e');
    return null;
  }
}
