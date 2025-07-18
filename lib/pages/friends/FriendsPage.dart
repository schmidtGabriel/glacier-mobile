import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/components/decorations/inputDecoration.dart';
import 'package:glacier/pages/friends/components/AcceptedFriendsList.dart';
import 'package:glacier/pages/friends/components/PendingFriendsList.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/user/getPendingUserFriends.dart';
import 'package:glacier/services/user/getUserFriends.dart';
import 'package:glacier/services/user/saveFriend.dart';
import 'package:glacier/services/user/updateFriendRequest.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

class FriendsPage extends StatefulWidget {
  final int? segment;

  const FriendsPage({super.key, this.segment});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  UserResource? user;
  List friends = [];
  List pendingFriends = [];
  bool isLoading = false;
  bool isLoadingDialog = false;
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
                            AcceptedFriendsList(
                              friends: friends,
                              user: user,
                              onInviteFriend: showInviteFriendDialog,
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
    _dialogEmailController.dispose();
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
          toastification.show(
            title: Text('Success!'),
            description: Text("Friend request processed!"),
            autoCloseDuration: const Duration(seconds: 5),
            type: ToastificationType.success,
            alignment: Alignment.bottomCenter,
          );
        })
        .catchError((error) {
          toastification.show(
            title: Text('Error.'),
            description: Text("Processing friend failed!"),
            autoCloseDuration: const Duration(seconds: 5),
            type: ToastificationType.error,
            alignment: Alignment.bottomCenter,
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
      prefs.getBool('invite') ?? false ? showInviteFriendDialog() : null;
      prefs.remove('invite'); // Clear invite flag after showing dialog
    });
  }

  Future<void> inviteFriendFromDialog(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    final email = _dialogEmailController.text.trim();
    if (email.isEmpty) return;

    setDialogState(() {
      isLoadingDialog = true;
    });

    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> userMap = jsonDecode(prefs.getString('user') ?? '{}');
    var user = UserResource.fromJson(userMap);

    saveFriend(user.uuid, email)
        .then(
          (value) async => {
            if (mounted) {setState(() {})},
            await getFriends(),
            await getPendingFriends(),

            toastification.show(
              title: Text(value.error == true ? 'Error!' : 'Success!'),
              description: Text(
                value.error == true
                    ? 'Error: ${value.message.toString()}'
                    : 'A friend request has been sent to $email.',
              ),
              autoCloseDuration: const Duration(seconds: 5),
              type:
                  value.error == true
                      ? ToastificationType.error
                      : ToastificationType.success,
              alignment: Alignment.bottomCenter,
            ),

            Navigator.of(dialogContext).pop(),
            _dialogEmailController.clear(),
            setDialogState(() {
              isLoadingDialog = false;
            }),
          },
        )
        .catchError((error) {
          toastification.show(
            title: Text('Friend Request failed'),
            description: Text('Error: ${error.message.toString()}'),
            autoCloseDuration: const Duration(seconds: 5),
            type: ToastificationType.error,
            alignment: Alignment.bottomCenter,
          );
          setDialogState(() {
            isLoadingDialog = false;
          });
          return error;
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

  void showInviteFriendDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
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
                    onSubmitted:
                        (_) => inviteFriendFromDialog(
                          dialogContext,
                          setDialogState,
                        ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _dialogEmailController.clear();
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed:
                      isLoadingDialog
                          ? null
                          : () => inviteFriendFromDialog(
                            dialogContext,
                            setDialogState,
                          ),
                  child:
                      isLoadingDialog
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            'Invite',
                            style: TextStyle(color: Colors.white),
                          ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
