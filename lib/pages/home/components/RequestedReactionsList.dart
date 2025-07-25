import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/components/UserAvatar.dart';
import 'package:glacier/helpers/formatStatusReaction.dart';
import 'package:glacier/services/reactions/listReactions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestedReactionsList extends StatefulWidget {
  final user;

  const RequestedReactionsList({super.key, required this.user});

  @override
  State<RequestedReactionsList> createState() => _RequestedReactionsListState();
}

class _RequestedReactionsListState extends State<RequestedReactionsList> {
  List reactions = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(child: CircularProgressIndicator()),
          ),
        )
        : RefreshIndicator.noSpinner(
          onRefresh: loadReactions,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setBool('invite', true);
                      });
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushReplacementNamed('/', arguments: {'index': 2});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Invite Friends',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                if (reactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'You’re all caught up, invite friends to get more requests!',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: reactions.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final reaction = reactions[index];
                    final title = reaction['title'] ?? 'No Name';
                    final createdBy = reaction['requested'];
                    return Container(
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
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade100,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              children: [
                                UserAvatar(user: createdBy, size: 32),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        createdBy?.name ?? 'Unknown',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
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
                                ),

                                if (reaction['status'] == '0')
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context, rootNavigator: true)
                                          .pushNamed(
                                            '/reaction',
                                            arguments: reaction,
                                          )
                                          .then((_) {
                                            loadReactions();
                                          });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 3,
                                        horizontal: 15,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade900,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Record',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 3,
                                      horizontal: 15,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorStatusReaction(
                                        reaction['status'],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      formatStatusReaction(reaction['status']),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.all(8),

                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      // Text(reaction['url'] ?? 'No Description'),
                                      // SizedBox(height: 8),
                                      Text(title),
                                      SizedBox(height: 2),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Duration: ${reaction['video_duration'].round() ?? '0'}s',
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

                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context)
                                        .pushNamed(
                                          '/reaction-detail',
                                          arguments: reaction,
                                        )
                                        .then((_) {
                                          loadReactions();
                                        });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Details',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.blue,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    loadReactions();
  }

  Future<void> loadReactions() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      List data = await listReactions(userId: widget.user.uuid);

      if (!mounted) return;

      setState(() {
        reactions = data;
      });

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('reactions', jsonEncode(data));
    } catch (e) {
      print('Error loading sent reactions: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
