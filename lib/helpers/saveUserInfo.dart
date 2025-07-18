import 'dart:convert';

import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:shared_preferences/shared_preferences.dart';

saveUserInfo(user) async {
  final prefs = await SharedPreferences.getInstance();
  var userData = {
    'uuid': user['uuid'],
    'name': user['name'],
    'email': user['email'],
    'phone': user['phone'],
    'created_at': user['created_at']?.toDate().toIso8601String(),
    'profile_picture':
        user.containsKey('profile_picture')
            ? await FirebaseStorageService().getDownloadUrl(
              user['profile_picture'],
            )
            : '',
    'status': user['status'] ?? 0,
    'role': user['role'] ?? 10,
  };

  // print('Saving user data: $userData');
  prefs.setString('user', jsonEncode(userData));
}
