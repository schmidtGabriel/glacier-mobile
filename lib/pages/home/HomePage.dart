import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glacier/components/RequestedReactionsList.dart';
import 'package:glacier/components/SentReactionsList.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/user/getUserFriends.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late UserResource user;
  late TabController _tabController;

  List reactions = [];
  bool isLoading = false;

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
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_circle,
                              size: 40,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Hello ${user.name}',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                ),
                              ),
                            ),

                            GestureDetector(
                              onTap: () async {
                                bool? shouldSignOut = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Sign Out'),
                                      content: Text(
                                        'Are you sure you want to sign out?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          child: Text('Sign Out'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldSignOut == true) {
                                  await FirebaseAuth.instance.signOut();
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.remove('user');
                                }
                              },
                              child: Icon(
                                Icons.logout,
                                size: 24,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TabBar(
                        controller: _tabController,
                        tabs: [Tab(text: 'Requested'), Tab(text: 'Sent')],
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
                            // Requested Reactions Tab
                            RequestedReactionsList(user: user),

                            // Sent Reactions Tab
                            SentReactionsList(user: user),
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadUserData();
  }

  Future<void> loadFriends() async {
    List friends = await getUserFriends();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('friends', jsonEncode(friends));
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

    loadFriends();
    setState(() {
      isLoading = false;
    });
  }
}
