import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

Future<void> updateRecentFriends(
  Map<String, dynamic>? friend, {
  bool isDelete = false,
}) async {
  if (friend == null) return;
  await SharedPreferences.getInstance().then((value) {
    var recentFriends = jsonDecode(value.getString('recent_friends') ?? '[]');

    // Remove the friend if already in the list
    recentFriends.removeWhere((x) => x['uuid'] == friend['uuid']);

    if (!isDelete) {
      // Add the friend to the start of the list
      recentFriends.insert(0, friend);
    }

    // Limit to the last 5 friends
    if (recentFriends.length > 5) {
      recentFriends = recentFriends.sublist(0, 5);
    }

    print('Updated recent friends: $recentFriends');

    value.setString('recent_friends', jsonEncode(recentFriends));
  });
}
