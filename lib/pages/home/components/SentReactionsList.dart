import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/helpers/formatStatusReaction.dart';
import 'package:glacier/resources/ReactionResource.dart';
import 'package:glacier/services/reactions/listReactions.dart';
import 'package:glacier/themes/theme_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SentReactionsList extends StatefulWidget {
  final user;

  const SentReactionsList({super.key, required this.user});

  @override
  State<SentReactionsList> createState() => _SentReactionsListState();
}

class _SentReactionsListState extends State<SentReactionsList> {
  List<ReactionResource> reactions = [];
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
            physics: AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height / 1.5,
                // Screen height minus padding
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushReplacementNamed('/gallery');
                      },

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
                      final title = reaction.title ?? 'No Name';
                      final user = reaction.assignedUser;

                      return Container(
                        decoration: ThemeContainers.card(context),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    context.isDarkMode
                                        ? Colors.blueGrey.shade800
                                        : Colors.blueGrey.shade200,

                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 3,
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorStatusReaction(
                                        reaction.status,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      formatStatusReaction(reaction.status),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    reaction.createdAt ?? 'No Date',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
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
                                              'Sent to: ${user?.name ?? reaction.invitedTo}',
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
                                          .then((value) {
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
      reactions =
          (await listReactions(
            userId: widget.user.uuid,
            isSent: true,
          )).cast<ReactionResource>();

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      prefs.setString(
        'reactions',
        jsonEncode(reactions.map((e) => e.toJson()).toList()),
      );
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
