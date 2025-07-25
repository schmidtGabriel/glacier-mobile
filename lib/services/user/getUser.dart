import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glacier/helpers/parseTimeStamp.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/FirebaseStorageService.dart';

Future<UserResource?> getUser(String uuid) async {
  try {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('uuid', isEqualTo: uuid)
            .limit(1)
            .get();
    if (querySnapshot.docs.isNotEmpty) {
      var data = querySnapshot.docs.first.data();
      return UserResource.fromJson({
        'uuid': data['uuid'],
        'name': data['name'],
        'email': data['email'],
        'created_at': formatTimestamp(data['created_at']),
        'profile_picture':
            querySnapshot.docs.first.data()['profile_picture'] != null
                ? await FirebaseStorageService().getDownloadUrl(
                  querySnapshot.docs.first.data()['profile_picture'],
                )
                : '',
      });
    } else {
      return null;
    }
  } catch (e) {
    print('Error fetching user data: $e');
    return null;
  }
}
