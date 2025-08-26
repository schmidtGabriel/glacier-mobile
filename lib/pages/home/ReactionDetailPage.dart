import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/enums/ReactionVideoOrientation.dart';
import 'package:glacier/enums/ReactionVideoSegment.dart';
import 'package:glacier/helpers/ToastHelper.dart';
import 'package:glacier/helpers/formatStatusReaction.dart';
import 'package:glacier/resources/ReactionResource.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/reactions/cancelReaction.dart';
import 'package:glacier/services/reactions/completeReaction.dart';
import 'package:glacier/services/reactions/createReactionVideo.dart';
import 'package:glacier/services/reactions/getReaction.dart';
import 'package:glacier/services/reactions/updateReaction.dart';
import 'package:glacier/themes/theme_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReactionDetailPage extends StatefulWidget {
  final String uuid;

  const ReactionDetailPage({super.key, required this.uuid});

  @override
  State<ReactionDetailPage> createState() => _ReactionDetailPageState();
}

class _ReactionDetailPageState extends State<ReactionDetailPage> {
  ReactionResource? reaction;
  UserResource? user;
  bool _isLoading = false; // Track loading state
  String loadingMessage = '';

  @override
  Widget build(BuildContext context) {
    final title = reaction?.title ?? 'No Title';
    final createdBy = reaction?.createdBy;
    final assignedUser = reaction?.assignedUser;
    var status = reaction?.status ?? '0';
    final createdAt = reaction?.createdAt ?? 'No Date';
    final videoUrl = reaction?.videoUrl ?? '';
    final reactionUrl = reaction?.reactionUrl ?? '';
    final recordUrl = reaction?.recordUrl ?? '';
    final videoDuration = reaction?.videoDuration?.round() ?? '0';

    print('Record URL: $recordUrl');

    final isStartRecording =
        status == '0' &&
        user?.uuid != reaction?.createdBy?.uuid &&
        videoUrl.isNotEmpty &&
        reactionUrl.isEmpty;
    final isSendReaction =
        status == '1' &&
        user?.uuid != createdBy?.uuid &&
        videoUrl.isNotEmpty &&
        reactionUrl.isNotEmpty;
    final isWatchRecord = status == '10' && recordUrl.isNotEmpty;
    final isWatchVideo = videoUrl.isNotEmpty && user?.uuid == createdBy?.uuid;
    final isCancelRequest = status == '0' && user?.uuid == createdBy?.uuid;

    print('Reaction: ${reaction?.uuid}');

    return _isLoading
        ? Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  loadingMessage,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        )
        : Scaffold(
          appBar: AppBar(
            title: Text(
              'Reaction Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: ThemeContainers.card(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colorStatusReaction(status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                formatStatusReaction(status),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Created on $createdAt',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // People Information
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: ThemeContainers.card(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'People Involved',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),

                        // Requested By
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Requested by',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    createdBy?.name ?? 'Unknown',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (assignedUser != null) ...[
                          SizedBox(height: 16),
                          Divider(color: Colors.grey[200]),
                          SizedBox(height: 16),

                          // Assigned To
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.assignment_ind_outlined,
                                  color: Colors.green[600],
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Assigned to',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      assignedUser.name ?? 'Unknown',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  if (reaction?.description != null &&
                      reaction!.description!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: ThemeContainers.card(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          SizedBox(height: 8),
                          Text(
                            reaction?.description ?? 'No Description',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],

                  // Video Information
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: ThemeContainers.card(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Video Information',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(height: 16),

                        // Duration
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Duration',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '$videoDuration seconds',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),

                        if (videoUrl.isNotEmpty &&
                            user?.uuid == createdBy?.uuid) ...[
                          SizedBox(height: 16),
                          Divider(color: Colors.grey[200]),
                          SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Action Buttons
                  if (isStartRecording) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushNamed('/reaction', arguments: reaction).then((
                            _,
                          ) {
                            // Optionally, you can refresh the state or navigate back
                            _loadReactionByUuid();
                          });
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.blue.shade400,
                              width: 2,
                            ),
                          ),
                          elevation: 2,
                        ),
                        icon: Icon(Icons.videocam),
                        label: Text(
                          'Start Recording',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (isSendReaction) ...[
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _completeReaction();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: Icon(Icons.send),
                        iconAlignment: IconAlignment.end,
                        label: Text(
                          'Send Reaction',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (isWatchRecord) ...[
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            () => Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushNamed(
                              '/preview-video',
                              arguments: {'videoPath': recordUrl},
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: Icon(Icons.play_arrow),
                        label: Text(
                          'Watch Reaction',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (isWatchVideo) ...[
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            () => Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushNamed(
                              '/preview-video',
                              arguments: {'videoPath': videoUrl},
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: Icon(Icons.play_arrow),
                        label: Text(
                          'Watch Video',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (isCancelRequest) ...[
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await cancelReactionRequest(reaction?.uuid ?? '');
                          setState(() {
                            status = '-10';
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: Icon(Icons.cancel_outlined),
                        label: Text(
                          'Cancel Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
  }

  cancelReactionRequest(String uuid) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Cancel Request'),
          content: Text('Are you sure you want to cancel this request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('No'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Logic to cancel the reaction request
                await cancelReaction(uuid);
                // Optionally, you can refresh the state or navigate bac
                Navigator.of(dialogContext).pop();
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadReactionByUuid();
  }

  Future<void> _completeReaction() async {
    if (reaction == null) return;

    setState(() {
      _isLoading = true;
      loadingMessage = 'Completing reaction...';
    });

    try {
      var resultReaction = await completeReaction(reaction, (progress, total) {
        // Handle progress updates if needed
      });

      if (resultReaction == null) {
        ToastHelper.showError(
          context,
          description: 'Failed to complete reaction, pleasetry again.',
        );
        return;
      }

      setState(() {
        loadingMessage = 'Updating reaction...';
      });

      await updateReaction(reaction?.uuid, {
        'status': '10',
        'record_path': resultReaction['recordPath'],
      });

      createReactionVideo({
        'reaction_id': reaction?.uuid,
        'video_path': resultReaction['recordPath'],
        'video_duration': reaction?.videoDuration,
        'video_orientation': ReactionVideoOrientation.portrait.value,
        'segment': ReactionVideoSegment.combinedVideo.value,
        'created_at': DateTime.now().toIso8601String(),
      });

      ToastHelper.showSuccess(
        context,
        description: 'Reaction completed successfully!',
      );
      await _loadReactionByUuid(); // Refresh the reaction data
    } catch (e) {
      print('Error completing reaction: $e');
    } finally {
      setState(() {
        _isLoading = false;
        loadingMessage = '';
      });
    }
  }

  Future<bool> _loadReactionByUuid() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();

    final userString = prefs.getString('user');
    if (userString != null) {
      user = UserResource.fromJson(jsonDecode(userString));
    } else {
      user = null; // Handle case where user data is not available
    }

    var currentReaction = await getReaction(widget.uuid ?? '');
    if (currentReaction != null) {
      setState(() {
        reaction = currentReaction;
        _isLoading = false; // Hide loading indicator
      });
      return true;
    }

    setState(() {
      _isLoading = false; // Hide loading indicator
    });
    return false; // Return false if no reaction is found
  }
}
