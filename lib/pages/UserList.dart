import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/components/UserAvatar.dart';
import 'package:glacier/helpers/updateRecentFriends.dart';
import 'package:glacier/resources/FriendResource.dart';
import 'package:glacier/services/user/getUserFriends.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  List<FriendResource> friends = [];
  List<FriendResource> filteredFriends = [];
  List recentFriends = [];

  bool friendsLoaded = false;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Search friends...',
            fillColor: Colors.white,
            filled: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          onChanged: (value) {
            // Implement search functionality here
            // For now, we will just print the search term
            print('Search term: $value');
            // You can implement the actual search logic here
            // For now, we will just filter the friends list
            setState(() {
              filteredFriends =
                  friends.where((friend) {
                    final friendName = friend.friend?.name.toLowerCase() ?? '';
                    return friendName.contains(value.toLowerCase());
                  }).toList();

              if (value.isEmpty) {
                filteredFriends = friends;
              }
            });
          },
        ),
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      friends.isEmpty
                          ? Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              "You haven't invited any friends yet.",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                          : Text(
                            'Recent Friends',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                      SizedBox(height: 8),
                      recentFriends.isEmpty
                          ? Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'No recent friends found.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: recentFriends.length,
                            itemBuilder: (context, index) {
                              final friend = recentFriends[index];
                              return ListTile(
                                onTap: () {
                                  Navigator.of(context).pop(friend);
                                },
                                leading: UserAvatar(user: friend),
                                title: Text(friend.name ?? ''),
                                subtitle: Text(friend.email ?? ''),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    updateRecentFriends(
                                      friend.toJson(),
                                      isDelete: true,
                                    );
                                    setState(() {
                                      recentFriends.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                      Text(
                        'All Friends',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),

                      filteredFriends.isEmpty
                          ? Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'No friends found.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: filteredFriends.length,
                            itemBuilder: (context, index) {
                              final friendData = filteredFriends[index];
                              final friend = friendData.friend;
                              return ListTile(
                                onTap: () {
                                  Navigator.of(context).pop(friend);
                                },
                                leading: UserAvatar(user: friend),
                                title: Text(friend?.name ?? ''),
                                subtitle: Text(friend?.email ?? ''),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  Future<void> loadFriends() async {
    setState(() {
      isLoading = true;
    });

    try {
      friends = (await getUserFriends()).cast<FriendResource>();
      filteredFriends = friends;
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('friends', jsonEncode(friends));

      recentFriends = jsonDecode(prefs.getString('recent_friends') ?? '[]');
      print(recentFriends);
      setState(() {});
    } catch (e) {
      print('Error fetching friends: $e');
      friends = [];
    }

    setState(() {
      isLoading = false;
    });
  }
}
