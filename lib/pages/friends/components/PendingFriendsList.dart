import 'package:flutter/material.dart';
import 'package:glacier/components/UserAvatar.dart';
import 'package:glacier/helpers/formatStatusInviteFriend.dart';
import 'package:glacier/resources/FriendResource.dart';
import 'package:glacier/themes/theme_extensions.dart';

class PendingFriendsList extends StatelessWidget {
  final List<FriendResource> pendingFriends;
  final Function(int, String) onHandleFriendRequest;

  const PendingFriendsList({
    super.key,
    required this.pendingFriends,
    required this.onHandleFriendRequest,
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
            pendingFriends.isEmpty
                ? Text(
                  "You don't have any new invites.",
                  style: Theme.of(context).textTheme.bodyMedium,
                )
                : ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: pendingFriends.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final friendData = pendingFriends[index];
                    final friend = friendData.friend;
                    final name =
                        friendData.friend?.name ?? friendData.invitedTo ?? '';
                    final email = friendData.friend?.email ?? '';

                    return Container(
                      padding: EdgeInsets.all(16),
                      decoration: ThemeContainers.card(context),
                      child: Row(
                        children: [
                          UserAvatar(
                            userName: name ?? '',
                            pictureUrl: friendData.friend?.profilePic ?? '',
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: friend == null ? 14 : 16,
                                    fontWeight: FontWeight.bold,
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
                          ),

                          if (friendData.isRequested == false) ...[
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () {
                                    onHandleFriendRequest(1, friendData.uuid);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    onHandleFriendRequest(-1, friendData.uuid);
                                  },
                                ),
                              ],
                            ),
                          ] else ...[
                            Badge(
                              padding: EdgeInsets.symmetric(
                                vertical: 3,
                                horizontal: 10,
                              ),
                              label: Text(
                                formatStatusInviteFriend(
                                  friendData.status ?? 0,
                                ),
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: colorStatusInviteFriend(
                                friendData.status ?? 0,
                              ),
                            ),
                          ],
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
