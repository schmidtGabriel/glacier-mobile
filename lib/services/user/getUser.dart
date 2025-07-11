import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glacier/services/FirebaseStorageService.dart';

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
        'profile_picture':
            querySnapshot.docs.first.data()['profile_picture'] != null
                ? await FirebaseStorageService().getDownloadUrl(
                  querySnapshot.docs.first.data()['profile_picture'],
                )
                : '',
      };
    } else {
      return null;
    }
  } catch (e) {
    print('Error fetching user data: $e');
    return null;
  }
}
