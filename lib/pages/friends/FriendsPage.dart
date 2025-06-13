import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/components/decorations/inputDecoration.dart';
import 'package:glacier/helpers/formatStatusInviteFriend.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/user/getUserFriends.dart';
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
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,

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
                              separatorBuilder: (_, __) => SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final friendData = friends[index];
                                final invitedUser = friendData['invited_user'];
                                final requestedUser =
                                    friendData['requested_user'];

                                // Null safety check before accessing uuid
                                final friend =
                                    (invitedUser != null &&
                                            invitedUser['uuid'] == user?.uuid)
                                        ? requestedUser
                                        : invitedUser;

                                final name =
                                    friend?['name'] ??
                                    friends[index]['invited_email'] ??
                                    'Unknown';
                                final email = friend?['email'] ?? '';

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    subtitle: null,
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.6,
                                              child: Text(
                                                name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),

                                            email.isEmpty
                                                ? SizedBox.shrink()
                                                : Text(
                                                  email,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 14,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                          ],
                                        ),
                                        Badge(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 3,
                                            horizontal: 10,
                                          ),
                                          label: Text(
                                            formatStatusInviteFriend(
                                              friendData['status'],
                                            ),
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor:
                                              colorStatusInviteFriend(
                                                friendData['status'],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
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

  Future<void> getFriends() async {
    List friends = await getUserFriends();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('friends', jsonEncode(friends));
    loadFriends();
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
    print(friends);
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
    setState(() {
      isLoading = true;
    });
    final email = _friendEmailController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> userMap = jsonDecode(prefs.getString('user') ?? '{}');
    var user = UserResource.fromJson(userMap);
    saveFriend(user.uuid, email)
        .then(
          (value) async => {
            if (mounted)
              {
                setState(() {
                  _friendEmailController.clear();
                }),
              },
            await getFriends(),
            setState(() {
              isLoading = false;
            }),

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(value.message ?? 'Friend invited successfully!'),
              ),
            ),
          },
        )
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.mensage ?? 'Error inviting friend'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            isLoading = false;
          });
          return error; // Return the error to satisfy the return type requirement
        });
  }
}
