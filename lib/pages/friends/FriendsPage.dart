import 'package:flutter/material.dart';
import 'package:glacier/components/decorations/inputDecoration.dart';
import 'package:glacier/helpers/FormatStatusReaction.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  String? uuid;
  String? email;
  String? name;
  List friends = [];
  bool isLoading = true;

  final _friendEmailController = TextEditingController();

  final List<String> _invitedFriends = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Invite New Friends",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _friendEmailController,
                          decoration: inputDecoration(
                            "Friend's Email",
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(Icons.add),
                              onPressed: _addFriend,
                            ),
                          ),
                          onSubmitted: (_) => _addFriend(),
                          onTapOutside: (event) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                        SizedBox(height: 32),
                        Text(
                          "Your Friends",
                          style: Theme.of(context).textTheme.titleLarge,
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
                              separatorBuilder: (_, __) => Divider(),
                              itemBuilder: (context, index) {
                                final reaction = friends[index];
                                final name =
                                    reaction['invited_user'] ?? 'No Name';
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/reaction',
                                      arguments: reaction,
                                    );
                                  },
                                  child: ListTile(
                                    title: Text(name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reaction['url'] ?? 'No Description',
                                        ),
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
                                              reaction['created_at'] ??
                                                  'No Date',
                                              textAlign: TextAlign.end,
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
      ),
    );
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
    // friends = await listReactions(userId: uuid!);
    // final prefs = await SharedPreferences.getInstance();
    // prefs.setString('friends', jsonEncode(friends));
    setState(() {
      isLoading = false;
    });
  }

  void _addFriend() {
    final email = _friendEmailController.text.trim();
    if (email.isNotEmpty && !_invitedFriends.contains(email)) {
      setState(() {
        _invitedFriends.add(email);
        _friendEmailController.clear();
      });
    }
  }
}
