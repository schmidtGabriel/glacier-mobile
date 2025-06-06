import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glacier/helpers/formatStatusReaction.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/reactions/listReactions.dart';
import 'package:glacier/services/user/getUserFriends.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late UserResource user;

  List reactions = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Hello ${user.name}',
                          style: TextStyle(color: Colors.black, fontSize: 20),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Requested Reactions",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      reactions.isEmpty
                          ? Text(
                            "No reactions found.",
                            style: TextStyle(color: Colors.grey),
                          )
                          : SizedBox.shrink(),
                      SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: reactions.length,
                        separatorBuilder:
                            (context, index) => SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final reaction = reactions[index];
                          final title = reaction['title'] ?? 'No Name';
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pushNamed('/reaction', arguments: reaction);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(title),
                                    Badge(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 3,
                                        horizontal: 10,
                                      ),
                                      label: Text(
                                        formatStatusReaction(
                                          reaction['status'],
                                        ),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: colorStatusReaction(
                                        reaction['status'],
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      // Text(reaction['url'] ?? 'No Description'),
                                      // SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Duration: ${reaction['video_duration'] ?? '0'}',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                          ),
                                          Text(
                                            reaction['created_at'] ?? 'No Date',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('user');
        },
        child: Icon(Icons.logout),
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

    loadUserData();
  }

  Future<void> loadFriends() async {
    List friends = await getUserFriends();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('friends', jsonEncode(friends));
  }

  Future<void> loadReactions() async {
    reactions = await listReactions(userId: user.uuid);
    final prefs = await SharedPreferences.getInstance();

    prefs.setString('reactions', jsonEncode(reactions));
  }

  Future<void> loadUserData() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> userMap = await jsonDecode(
      prefs.getString('user') ?? '{}',
    );

    user = UserResource.fromJson(userMap);

    await loadReactions();
    loadFriends();
    setState(() {
      isLoading = false;
    });
  }
}
