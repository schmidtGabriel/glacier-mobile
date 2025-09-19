import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/components/AddFriendBottomSheet.dart';
import 'package:glacier/helpers/ToastHelper.dart';
import 'package:glacier/pages/friends/components/AcceptedFriendsList.dart';
import 'package:glacier/pages/friends/components/PendingFriendsList.dart';
import 'package:glacier/resources/FriendResource.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/user/getPendingUserFriends.dart';
import 'package:glacier/services/user/getUserFriends.dart';
import 'package:glacier/services/user/updateFriendRequest.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendsPage extends StatefulWidget {
  final int? segment;

  const FriendsPage({super.key, this.segment});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  UserResource? user;
  List<FriendResource> friends = [];
  List<FriendResource> pendingFriends = [];
  bool isLoading = false;
  bool isLoadingDialog = false;
  late TabController _tabController;

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

                        indicatorPadding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            AcceptedFriendsList(
                              friends: friends,
                              user: user,
                              onInviteFriend: _showAddFriendBottomSheet,
                            ),
                            PendingFriendsList(
                              pendingFriends: pendingFriends,
                              onHandleFriendRequest: handleFriendRequest,
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
    _tabController.dispose();
    super.dispose();
  }

  Future<void> getFriends() async {
    try {
      friends = await getUserFriends();
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('friends', jsonEncode(friends));
      setState(() {});
    } catch (e) {
      print('Error fetching friends: $e');
      friends = [];
    }
  }

  Future<void> getPendingFriends() async {
    try {
      pendingFriends = await getPendingUserFriends();
      setState(() {});
    } catch (e) {
      print('Error fetching pending friends: $e');
      pendingFriends = [];
    }
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
          ToastHelper.showSuccess(
            context,
            description: 'Friend request processed successfully!',
          );
        })
        .catchError((error) {
          ToastHelper.showError(
            context,
            description: 'Error processing friend request.',
          );
        });
  }

  Future<void> initFriends() async {
    setState(() {
      isLoading = true;
    });

    await getFriends();
    await getPendingFriends();
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = widget.segment ?? 0;
    loadUserData();
    initFriends();

    SharedPreferences.getInstance().then((prefs) {
      prefs.getBool('invite') ?? false ? _showAddFriendBottomSheet() : null;
      prefs.remove('invite'); // Clear invite flag after showing dialog
    });
  }

  Future<void> loadUserData() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> userMap = jsonDecode(prefs.getString('user') ?? '{}');
    user = UserResource.fromJson(userMap);
    await getFriends();
    setState(() {
      isLoading = false;
    });
  }

  void _showAddFriendBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return AddFriendBottomSheet(
          initialName: '',
          onSubmit: (String name, String emailOrPhone) async {
            getPendingFriends();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
