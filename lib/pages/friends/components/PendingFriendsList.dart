import 'package:flutter/material.dart';
import 'package:glacier/components/UserAvatar.dart';
import 'package:glacier/helpers/formatStatusInviteFriend.dart';

class PendingFriendsList extends StatelessWidget {
  final List pendingFriends;
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
                  "You haven't have new invites.",
                  style: Theme.of(context).textTheme.bodyMedium,
                )
                : ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: pendingFriends.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final friendData = pendingFriends[index];
                    var isRequested = friendData['isRequested'] ?? false;

                    final friend =
                        isRequested
                            ? friendData['invited_user']
                            : friendData['requested_user'];

                    final name =
                        friend?['name'] ??
                        friendData['invited_email'] ??
                        'Unknown';
                    final email = friend?['email'] ?? '';

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

                          if (!isRequested) ...[
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () {
                                    onHandleFriendRequest(
                                      1,
                                      friendData['uuid'],
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    onHandleFriendRequest(
                                      -1,
                                      friendData['uuid'],
                                    );
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
                                formatStatusInviteFriend(friendData['status']),
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: colorStatusInviteFriend(
                                friendData['status'],
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
