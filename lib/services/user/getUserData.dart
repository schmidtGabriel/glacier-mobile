import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>?> getUserData() async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return null;

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('uuid', isEqualTo: uid)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      await saveUserInfo(querySnapshot.docs.first.data());

      return querySnapshot.docs.first.data();
    } else {
      return null;
    }
  } catch (e) {
    print('Error fetching user data: $e');
    return null;
  }
}

saveUserInfo(user) async {
  final prefs = await SharedPreferences.getInstance();
  var userData = {
    'uuid': user['uuid'],
    'name': user['name'],
    'email': user['email'],
    'phone': user['phone'],
    'created_at': user['created_at']?.toDate().toIso8601String(),
    'status': user['status'] ?? 0,
    'role': user['role'] ?? 10,
  };
  print('Saving user data: $userData');
  prefs.setString('user', jsonEncode(userData));
}
