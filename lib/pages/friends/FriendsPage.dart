import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/components/decorations/inputDecoration.dart';
import 'package:glacier/helpers/formatStatusInviteFriend.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/user/getPendingUserFriends.dart';
import 'package:glacier/services/user/getUserFriends.dart';
import 'package:glacier/services/user/saveFriend.dart';
import 'package:glacier/services/user/updateFriendRequest.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  UserResource? user;
  List friends = [];
  List pendingFriends = [];
  bool isLoading = true;
  late TabController _tabController;

  final _dialogEmailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child:
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TabBar(
                        controller: _tabController,
                        tabs: [Tab(text: 'Friends'), Tab(text: 'Invites')],
                        labelColor: Colors.blue,
                        unselectedLabelColor: Colors.grey,
                        dividerColor: Colors.transparent,
                        indicatorColor: Colors.blue,
                        indicatorWeight: 2.0,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: showInviteFriendDialog,
                                      child: Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor:
                                                  Colors.grey.shade300,
                                              child: Icon(
                                                Icons.person_add,
                                                color: Colors.grey.shade600,
                                                size: 24,
                                              ),
                                            ),

                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Text('Invite new friend.'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    friends.isEmpty
                                        ? Text(
                                          "You haven't invited any friends yet.",
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                        )
                                        : ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          itemCount: friends.length,
                                          separatorBuilder:
                                              (_, __) => SizedBox(height: 8),
                                          itemBuilder: (context, index) {
                                            final friendData = friends[index];
                                            final invitedUser =
                                                friendData['invited_user'];
                                            final requestedUser =
                                                friendData['requested_user'];

                                            // Null safety check before accessing uuid
                                            final friend =
                                                (invitedUser != null &&
                                                        invitedUser['uuid'] ==
                                                            user?.uuid)
                                                    ? requestedUser
                                                    : invitedUser;

                                            final name =
                                                friend?['name'] ??
                                                friends[index]['invited_email'] ??
                                                'Unknown';
                                            final email =
                                                friend?['email'] ?? '';

                                            return Container(
                                              padding: EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.1),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 24,
                                                    backgroundColor:
                                                        Colors.grey.shade300,
                                                    child: Text(
                                                      name.isNotEmpty
                                                          ? name[0]
                                                              .toUpperCase()
                                                          : '?',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          name,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),

                                                        email.isEmpty
                                                            ? SizedBox.shrink()
                                                            : Text(
                                                              email,
                                                              style: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .grey
                                                                        .shade700,
                                                                fontSize: 14,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                              ),
                                                            ),
                                                      ],
                                                    ),
                                                  ),
                                                  Badge(
                                                    padding:
                                                        EdgeInsets.symmetric(
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
                                            );
                                          },
                                        ),
                                  ],
                                ),
                              ),
                            ),

                            SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 16),

                                    pendingFriends.isEmpty
                                        ? Text(
                                          "You haven't have new invites.",
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                        )
                                        : ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          itemCount: pendingFriends.length,
                                          separatorBuilder:
                                              (_, __) => SizedBox(height: 8),
                                          itemBuilder: (context, index) {
                                            final friendData =
                                                pendingFriends[index];

                                            final requestedUser =
                                                friendData['requested_user'];

                                            // Null safety check before accessing uuid
                                            final friend = requestedUser;

                                            final name =
                                                requestedUser?['name'] ??
                                                friendData['invited_email'] ??
                                                'Unknown';
                                            final email =
                                                friend?['email'] ?? '';

                                            return Container(
                                              padding: EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.1),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 24,
                                                    backgroundColor:
                                                        Colors.grey.shade300,
                                                    child: Text(
                                                      name.isNotEmpty
                                                          ? name[0]
                                                              .toUpperCase()
                                                          : '?',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          name,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),

                                                        email.isEmpty
                                                            ? SizedBox.shrink()
                                                            : Text(
                                                              email,
                                                              style: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .grey
                                                                        .shade700,
                                                                fontSize: 14,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                              ),
                                                            ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      //add two buttons, one for accept and one for reject
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.check,
                                                          color: Colors.green,
                                                        ),
                                                        onPressed: () {
                                                          // Handle accept friend request
                                                          handleFriendRequest(
                                                            1,
                                                            friendData['uuid'],
                                                          );
                                                        },
                                                      ),

                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.close,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed: () {
                                                          // Handle reject friend request
                                                          handleFriendRequest(
                                                            -1,
                                                            friendData['uuid'],
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dialogEmailController.dispose();
    super.dispose();
  }

  Future<void> getFriends() async {
    List friends = await getUserFriends();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('friends', jsonEncode(friends));
    loadFriends();
  }

  Future<void> getPendingFriends() async {
    setState(() {
      isLoading = true;
    });
    pendingFriends = await getPendingUserFriends();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('pending_friends', jsonEncode(pendingFriends));
    setState(() {
      isLoading = false;
    });
  }

  Future<void> handleFriendRequest(status, uuid) async {
    await updateFriendRequest(status, uuid)
        .then((value) async {
          if (mounted) {
            await getPendingFriends();
            await getFriends();
            setState(() {
              isLoading = false;
            });
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Friend request accepted!')));
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error accepting friend request'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    getPendingFriends();
    loadUserData();
  }

  Future<void> inviteFriendFromDialog() async {
    final email = _dialogEmailController.text.trim();
    if (email.isEmpty) return;

    Navigator.of(context).pop(); // Close dialog first
    _dialogEmailController.clear();

    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> userMap = jsonDecode(prefs.getString('user') ?? '{}');
    var user = UserResource.fromJson(userMap);

    saveFriend(user.uuid, email)
        .then(
          (value) async => {
            if (mounted)
              {
                setState(() {
                  // No need to clear controller here as it's already cleared
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
          return error;
        });
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

  void showInviteFriendDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invite Friend'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send an invitation to a friend by entering their email address.',
              ),
              SizedBox(height: 16),
              TextField(
                controller: _dialogEmailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: inputDecoration("Friend's Email"),
                autofocus: true,
                onSubmitted: (_) => inviteFriendFromDialog(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _dialogEmailController.clear();
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: inviteFriendFromDialog,
              child: Text('Invite', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
