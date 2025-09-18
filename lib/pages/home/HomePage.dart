import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/components/UserAvatar.dart';
import 'package:glacier/pages/home/components/RequestedReactionsList.dart';
import 'package:glacier/pages/home/components/SentReactionsList.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/auth/getFCMToken.dart';
import 'package:glacier/services/user/getUserFriends.dart';
import 'package:glacier/themes/app_colors.dart';
import 'package:glacier/themes/theme_extensions.dart';
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
  int currentIndex = 0;

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
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed('/profile').then((_) {
                                    // Reload user data after returning from profile page
                                    loadUserData();
                                  });
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    UserAvatar(
                                      userName: user.name,
                                      pictureUrl: user.profilePic,
                                    ),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hello ${user.name}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge?.copyWith(
                                            color:
                                                context.isDarkMode
                                                    ? AppColors.primaryDark
                                                    : AppColors.secondaryDark,
                                          ),
                                        ),

                                        Text(
                                          user.email,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color:
                              context.isDarkMode
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.lightSurfaceVariant,
                        ),

                        child: TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(
                              child: Row(
                                spacing: 5,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_rounded),
                                  Text('Received'),
                                ],
                              ),
                            ),

                            Tab(
                              child: Row(
                                spacing: 5,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.outbox_outlined),
                                  Text('Sent'),
                                ],
                              ),
                            ),
                          ],

                          unselectedLabelStyle: TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
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
    _tabController.addListener(() {
      setState(() {
        currentIndex = _tabController.index;
      });
    });
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

    openPermissionsPage();
  }

  void openPermissionsPage() async {
    // Navigate to the permissions page if permissions are not granted
    final prefs = await SharedPreferences.getInstance();
    final permissionsGranted = prefs.getBool('permissionsGranted') ?? false;
    if (!permissionsGranted) {
      Navigator.of(context, rootNavigator: true).pushNamed('/permissions').then(
        (_) {
          // Reload the current page after permissions are granted
          prefs.setBool('permissionsGranted', true);
          initFCM();
          setState(() {});
          // openSubscriptionPage();
        },
      );
    } else {
      initFCM();
      // openSubscriptionPage();
    }
  }

  void openSubscriptionPage() async {
    if (user.hasActiveSubscription == false) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed('/subscription').then((_) {
        // Reload the current page after permissions are granted
      });
    }
  }
}
