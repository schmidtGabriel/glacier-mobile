import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glacier/helpers/FormatStatusReaction.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/reactions/listReactions.dart';
import 'package:glacier/services/user/getUserData.dart';
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

                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: reactions.length,
                        separatorBuilder: (_, __) => Divider(),
                        itemBuilder: (context, index) {
                          final reaction = reactions[index];
                          final title = reaction['title'] ?? 'No Name';
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/reaction',
                                arguments: reaction,
                              );
                            },
                            child: ListTile(
                              title: Text(title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(reaction['url'] ?? 'No Description'),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        FormatStatusReaction(
                                          reaction['status'],
                                        ),
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
    await getUserData();
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> userMap = jsonDecode(prefs.getString('user') ?? '{}');

    user = UserResource.fromJson(userMap);

    await loadReactions();
    loadFriends();
    setState(() {
      isLoading = false;
    });
  }
}
