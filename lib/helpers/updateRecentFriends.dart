import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

void updateRecentFriends(
  Map<String, dynamic>? friend, {
  bool isDelete = false,
}) async {
  if (friend == null) return;

  final prefs = await SharedPreferences.getInstance();
  List<Map<String, dynamic>> recentFriends = jsonDecode(
    prefs.getString('recent_friends') ?? '[]',
  );

  // Remove the friend if already in the list
  recentFriends.remove(friend);

  if (!isDelete) {
    // Add the friend to the start of the list
    recentFriends.insert(0, friend);
  }

  // Limit to the last 5 friends
  if (recentFriends.length > 5) {
    recentFriends = recentFriends.sublist(0, 5);
  }

  await prefs.setString('recent_friends', jsonEncode(recentFriends));
}
