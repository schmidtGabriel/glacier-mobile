import 'dart:convert';

import 'package:glacier/helpers/parseTimeStamp.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:shared_preferences/shared_preferences.dart';

saveUserInfo(user) async {
  final prefs = await SharedPreferences.getInstance();
  var userData = UserResource.fromJson({
    ...user,
    'created_at': formatTimestamp(user['created_at']),
    'profile_picture':
        user.containsKey('profile_picture')
            ? await FirebaseStorageService().getDownloadUrl(
              user['profile_picture'],
            )
            : '',
  });

  prefs.setString('user', jsonEncode(userData.toJson()));
}
