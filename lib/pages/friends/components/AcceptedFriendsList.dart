import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/components/UserAvatar.dart';
import 'package:glacier/resources/FriendResource.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AcceptedFriendsList extends StatelessWidget {
  final List<FriendResource> friends;
  final UserResource? user;
  final VoidCallback onInviteFriend;

  const AcceptedFriendsList({
    super.key,
    required this.friends,
    required this.user,
    required this.onInviteFriend,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            GestureDetector(
              onTap: onInviteFriend,
              child: Container(
                padding: EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade300,
                      child: Icon(
                        Icons.person_add,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(child: Text('Invite new friend.')),
                  ],
                ),
              ),
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
                    final UserResource friend = friendData.friend!;
                    final name = friend.name;
                    final email = friend.email;

                    return Container(
                      padding: EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          UserAvatar(user: friend),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, overflow: TextOverflow.ellipsis),
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
                          ),

                          GestureDetector(
                            onTap: () {
                              SharedPreferences.getInstance().then((prefs) {
                                prefs.setString(
                                  'request_user',
                                  jsonEncode(friend.toJson()),
                                );
                              });
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pushReplacementNamed('/gallery');
                            },
                            child: Icon(
                              Icons.send,
                              color: Colors.blue.shade600,
                              size: 24,
                            ),
                          ),

                          // Badge(
                          //   padding: EdgeInsets.symmetric(
                          //     vertical: 3,
                          //     horizontal: 10,
                          //   ),
                          //   label: Text(
                          //     formatStatusInviteFriend(friendData['status']),
                          //     style: TextStyle(color: Colors.white),
                          //   ),
                          //   backgroundColor: colorStatusInviteFriend(
                          //     friendData['status'],
                          //   ),
                          // ),
                        ],
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
