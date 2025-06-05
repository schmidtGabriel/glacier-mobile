import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/components/decorations/inputDecoration.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/user/saveFriend.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  UserResource? user;
  List friends = [];
  bool isLoading = true;

  final _friendEmailController = TextEditingController();

  final List<String> _invitedFriends = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Invite New Friends",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _friendEmailController,
                          decoration: inputDecoration(
                            "Friend's Email",
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(Icons.add),
                              onPressed: _addFriend,
                            ),
                          ),
                          onSubmitted: (_) => _addFriend(),
                          onTapOutside: (event) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                        SizedBox(height: 32),
                        Text(
                          "Your Friends",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        friends.isEmpty
                            ? Text(
                              "You haven't invited any friends yet.",
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                            : ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: friends.length,
                              separatorBuilder: (_, __) => Divider(),
                              itemBuilder: (context, index) {
                                final friend =
                                    friends[index]['invited_user']['uuid'] ==
                                            user?.uuid
                                        ? friends[index]['requested_user']
                                        : friends[index]['invited_user'];
                                final name = friend['name'] ?? 'No Name';
                                final email = friend['email'] ?? 'No Email';

                                return ListTile(
                                  title: Text('$name - $email'),
                                  subtitle: null,
                                );
                              },
                            ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    loadUserData();
  }

  Future<void> loadFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final friendsPrefs = prefs.getString('friends');
    if (friendsPrefs != null) {
      friends = jsonDecode(friendsPrefs);
    } else {
      friends = [];
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadUserData() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> userMap = jsonDecode(prefs.getString('user') ?? '{}');
    user = UserResource.fromJson(userMap);
    await loadFriends();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _addFriend() async {
    final email = _friendEmailController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> userMap = jsonDecode(prefs.getString('user') ?? '{}');
    var user = UserResource.fromJson(userMap);

    await saveFriend(user.uuid, email);

    _friendEmailController.clear();
  }
}
