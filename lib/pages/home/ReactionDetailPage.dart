import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/helpers/formatStatusReaction.dart';
import 'package:glacier/services/reactions/cancelReaction.dart';
import 'package:glacier/services/reactions/getReaction.dart';
import 'package:glacier/themes/theme_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReactionDetailPage extends StatefulWidget {
  final String uuid;

  const ReactionDetailPage({super.key, required this.uuid});

  @override
  State<ReactionDetailPage> createState() => _ReactionDetailPageState();
}

class _ReactionDetailPageState extends State<ReactionDetailPage> {
  Map<String, dynamic>? reaction;
  Map<String, dynamic>? user;
  bool _isLoading = false; // Track loading state

  @override
  Widget build(BuildContext context) {
    final title = reaction?['title'] ?? 'No Title';
    final createdBy = reaction?['requested'];
    final assignedUser = reaction?['user'];
    var status = reaction?['status'] ?? '0';
    final createdAt = reaction?['created_at'] ?? 'No Date';
    final videoUrl = reaction?['url'] ?? '';
    final recordedUrl = reaction?['recordedUrl'] ?? '';
    final videoDuration = reaction?['video_duration'].round() ?? '0';
    return _isLoading
        ? Scaffold(body: Center(child: CircularProgressIndicator()))
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
                                      assignedUser?.name ?? 'Unknown',
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

                  if (reaction!.containsKey('description') &&
                      reaction?['description'] != null) ...[
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
                            reaction?['description'] ?? 'No Description',
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
                            user?['uuid'] == createdBy.uuid) ...[
                          SizedBox(height: 16),
                          Divider(color: Colors.grey[200]),
                          SizedBox(height: 16),

                          // Video URL
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.link,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Video URL',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      videoUrl,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color: Colors.blue[700],
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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

                  SizedBox(height: 30),

                  // Action Buttons
                  if (status == '0' &&
                      user?['uuid'] != createdBy.uuid &&
                      videoUrl.isNotEmpty) ...[
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

                  if (status == '1' && recordedUrl.isNotEmpty) ...[
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
                              arguments: {'videoPath': recordedUrl},
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

                  if (videoUrl.isNotEmpty &&
                      user?['uuid'] == createdBy.uuid) ...[
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

                  if (status == '0' && user?['uuid'] == createdBy.uuid) ...[
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            () => {
                              cancelReactionRequest(reaction?['uuid'] ?? ''),
                              setState(() {
                                status = '-10';
                              }),
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

  Future<bool> _loadReactionByUuid() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();

    final userString = prefs.getString('user');
    if (userString != null) {
      user = jsonDecode(userString);
    } else {
      user = null; // Handle case where user data is not available
    }

    var currentReaction = await getReaction(widget.uuid ?? '');
    if (currentReaction != null) {
      setState(() {
        reaction = Map<String, dynamic>.from(currentReaction);
        _isLoading = false; // Hide loading indicator
      });
      return true;
    }
    print('No reaction found for UUID: ${widget.uuid}');

    setState(() {
      _isLoading = false; // Hide loading indicator
    });
    return false; // Return false if no reaction is found
  }
}
