import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/components/ReactionStatusTag.dart';
import 'package:glacier/components/UserAvatar.dart';
import 'package:glacier/helpers/formatDate.dart';
import 'package:glacier/resources/ReactionResource.dart';
import 'package:glacier/services/reactions/listReactions.dart';
import 'package:glacier/themes/app_colors.dart';
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
                          Icon(Icons.add),
                          SizedBox(width: 8),
                          Text('New Request'),
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
                      final title = reaction.title ?? 'No Title';
                      final createdBy = reaction.createdBy;
                      final user = reaction.assignedUser;

                      return GestureDetector(
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
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: ThemeContainers.card(context),
                          child: IntrinsicHeight(
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 12,
                              children: [
                                UserAvatar(
                                  userName: user?.name ?? '',
                                  pictureUrl: user?.profilePic ?? '',
                                  size: 55,
                                ),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color:
                                              context.isDarkMode
                                                  ? Colors.white
                                                  : AppColors.secondary,
                                        ),
                                      ),
                                      Text(
                                        'Duration: ${reaction.videoDuration?.round() ?? '0'}s',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'To: ${user?.name ?? reaction.invitedTo}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),

                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatDate(
                                        reaction.createdAt,
                                        format: 'LLL dd',
                                      ),
                                      style: TextStyle(
                                        color:
                                            context.isDarkMode
                                                ? Colors.grey
                                                : AppColors.secondaryDark,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ReactionStatusTag(
                                      reaction: reaction,
                                      loadReactions: loadReactions,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
