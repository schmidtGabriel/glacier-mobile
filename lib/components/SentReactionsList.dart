import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/helpers/formatStatusReaction.dart';
import 'package:glacier/services/reactions/listReactions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SentReactionsList extends StatefulWidget {
  final user;

  const SentReactionsList({super.key, required this.user});

  @override
  State<SentReactionsList> createState() => _SentReactionsListState();
}

class _SentReactionsListState extends State<SentReactionsList> {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushReplacementNamed('/', arguments: {'index': 1});
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
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'New Request',
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
                        'Send your first request to get your friends real reaction!',
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
                    final user = reaction['user'];
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
                            padding: EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade100,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
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
                                Text(
                                  reaction['created_at'] ?? 'No Date',
                                  style: Theme.of(context).textTheme.bodySmall,
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
                                            'Sent to: ${user['name'] ?? '0'}',
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
                                    Navigator.of(context).pushNamed(
                                      '/reaction-detail',
                                      arguments: reaction,
                                    );
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
      List data = await listReactions(userId: widget.user.uuid, isSent: true);

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
