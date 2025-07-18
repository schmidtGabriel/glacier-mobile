import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glacier/resources/UserResource.dart';

class UserService {
  static const int pageSize = 10;

  static DocumentSnapshot? _lastDoc;

  static Future<List<UserResource>> fetchUsers(int page, String search) async {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('name')
        .limit(pageSize);

    if (search.isNotEmpty) {
      query = FirebaseFirestore.instance
          .collection('users')
          .orderBy('name')
          .startAt([search])
          .endAt(["$search\uf8ff"])
          .limit(pageSize);
      _lastDoc = null; // reset
    } else if (page > 1 && _lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    } else {
      _lastDoc = null;
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
    }

    return snapshot.docs
        .map((doc) => UserResource.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  static void resetPagination() {
    _lastDoc = null;
  }
}
