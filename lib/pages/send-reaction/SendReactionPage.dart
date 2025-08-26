import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:glacier/components/Button.dart';
import 'package:glacier/components/UserAvatar.dart';
import 'package:glacier/enums/ReactionVideoOrientation.dart';
import 'package:glacier/enums/ReactionVideoSegment.dart';
import 'package:glacier/helpers/ToastHelper.dart';
import 'package:glacier/helpers/updateRecentFriends.dart';
import 'package:glacier/pages/PreviewVideoPage.dart';
import 'package:glacier/pages/UserInvite.dart';
import 'package:glacier/pages/UserList.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:glacier/services/reactions/createReaction.dart';
import 'package:glacier/services/reactions/createReactionVideo.dart';
import 'package:glacier/services/reactions/updateReaction.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

class SendReactionPage extends StatefulWidget {
  final AssetEntity? video;
  final int duration;

  const SendReactionPage({super.key, required this.video, this.duration = 0});

  @override
  State<SendReactionPage> createState() => _SendReactionPageState();
}

class _SendReactionPageState extends State<SendReactionPage> {
  String? uuid;
  String? email;
  String? name;

  List friends = [];
  bool isLoading = false;
  bool isLoadingSubmit = false;
  String _filePath = '';
  int _duration = 0;
  String userId = '';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  UserResource? selectedFriend;
  String? selectedFriendEmail;
  String? selectedVideoType;
  AssetEntity? _selectedVideo;

  final uploadService = FirebaseStorageService();

  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Reaction'),
        leading: BackButton(
          onPressed: () {
            clearTextFields();
            Navigator.of(context).pop();
          },
        ),
      ),

      body: SafeArea(
        child:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedVideo != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder<Uint8List?>(
                                future: _selectedVideo?.thumbnailDataWithSize(
                                  ThumbnailSize(200, 200),
                                ),
                                builder: (_, snapshot) {
                                  final thumb = snapshot.data;
                                  if (thumb == null) {
                                    return Container(color: Colors.grey);
                                  }
                                  return GestureDetector(
                                    onTap: () async {
                                      await Navigator.push<AssetEntity?>(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => PreviewVideoPage(
                                                localVideo: _selectedVideo,
                                                hasConfirmButton: false,
                                              ),
                                        ),
                                      );
                                    },
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,

                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.memory(
                                            thumb,
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned(
                                            bottom: 4,
                                            right: 4,
                                            child: Icon(
                                              Icons.play_circle_fill,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                      SizedBox(height: 16),

                      Text(
                        "Title",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(labelText: "Enter title"),
                        onTapOutside: (event) {
                          FocusScope.of(context).unfocus();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      Text(
                        "Description",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        minLines: 4,
                        maxLines: 6,
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: "Enter description",
                        ),
                        onTapOutside: (event) {
                          FocusScope.of(context).unfocus();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20),

                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Clear focus from any text fields before navigation
                            FocusScope.of(context).unfocus();

                            final selectedUser =
                                await Navigator.push<UserResource>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserList(),
                                  ),
                                );

                            if (selectedUser != null) {
                              setState(() {
                                selectedFriend = selectedUser;
                                selectedFriendEmail = selectedUser.email;
                              });
                            }
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: const Text(
                            'Find friend',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),

                      SizedBox(height: 8),

                      Center(
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),

                      SizedBox(
                        height: 30,
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () async {
                            // Clear focus from any text fields before navigation
                            FocusScope.of(context).unfocus();

                            final selectedUser = await Navigator.push<String?>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserInvite(),
                              ),
                            );

                            if (selectedUser != null) {
                              setState(() {
                                selectedFriend = null;
                                selectedFriendEmail = selectedUser;
                              });
                            }
                          },
                          child: Center(
                            child: Text(
                              'Enter an email or SMS to invite a user',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      if (selectedFriend != null ||
                          selectedFriendEmail != null) ...[
                        SizedBox(height: 8),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sending to:",
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 8),

                            Row(
                              children: [
                                UserAvatar(
                                  userName: selectedFriend?.name,
                                  pictureUrl: selectedFriend?.profilePic,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedFriend?.name ??
                                            'Glacier`s Invitation',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        selectedFriend?.email ??
                                            selectedFriendEmail ??
                                            '',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        if (selectedFriend == null) ...[
                          SizedBox(height: 8),
                          Text(
                            'An invitation will be sent to their email.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade400,
                            ),
                          ),
                          SizedBox(height: 2),

                          Text(
                            'They’ll need to join the app to connect with you.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ],
                        SizedBox(height: 24),

                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Button(
                              isLoading: isLoadingSubmit,
                              loadingLabel:
                                  '${(_uploadProgress * 100).toStringAsFixed(0)}% Sending...',
                              onPressed: _sendReaction,
                              label: 'Send Reaction',
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                            ),

                        if (_uploadProgress > 0) ...[
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: LinearProgressIndicator(
                              value: _uploadProgress,
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ],
                    ],
                  ),
                ),
      ),
    );
  }

  clearTextFields() {
    if (mounted) {
      setState(() {
        _titleController.clear();
        _descriptionController.clear();
        _selectedVideo = null;
        _uploadProgress = 0.0;
        _selectedVideo = null;
        _filePath = '';
        _duration = 0;
        isLoading = false;
        selectedFriend = null;
        selectedFriendEmail = null;
        selectedVideoType = null;
      });
    }
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('request_user');
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> handleUploadVideo(
    reactionId,
    resolution,
  ) async {
    if (_selectedVideo == null) {
      ToastHelper.showWarning(
        context,
        description: 'Please select a video to upload.',
      );

      return null;
    }

    File? file = await _selectedVideo?.file;
    String filePath = file?.path ?? '';

    return await uploadService
        .uploadVideo(
          filePath,
          'sources',
          reactionId,
          onProgress: (sent, total) {
            setState(() {
              if (total > 0 && sent.isFinite && total.isFinite) {
                _uploadProgress = (sent / total);
              }
            });
          },
        )
        .then((value) async {
          final file = filePath;

          // var resultReaction = await convertReactionVideo(
          //   reactionId ?? '',
          //   'temp-sources/$reactionId.mp4',
          //   'sources/$reactionId.mp4',
          //   (progress, total) {
          //     setState(() {
          //       if (total > 0 &&
          //           progress.isFinite &&
          //           total.isFinite &&
          //           _uploadProgress.isFinite) {
          //         _uploadProgress = (_uploadProgress + (progress / total)) / 2;
          //       }
          //     });
          //   },
          //   {'resolution': resolution},
          // );

          // if (resultReaction == null) {
          //   ToastHelper.showError(
          //     context,
          //     description:
          //         'Failed to process the source video. Please try again.',
          //   );
          //   return null;
          // }
          File(file).delete();
          return value;
          // print('Value returned from convertReactionVideo: $resultReaction');
          // return resultReaction;
        });
  }

  @override
  void initState() {
    super.initState();
    loadVideo();
  }

  void loadVideo() async {
    if (widget.video == null) return;

    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    selectedFriend =
        prefs.getString('request_user') != null
            ? UserResource.fromJson(
              jsonDecode(prefs.getString('request_user')!),
            )
            : null;
    _selectedVideo = widget.video;
    _duration = widget.duration;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _sendReaction() async {
    setState(() {
      isLoadingSubmit = true;
    });

    if (_selectedVideo == null) {
      toastification.show(
        title: Text('Warning'),
        description: Text("You have to pick a video first."),
        autoCloseDuration: const Duration(seconds: 5),
        type: ToastificationType.warning,
        alignment: Alignment.bottomCenter,
      );
      setState(() {
        isLoadingSubmit = false;
      });
      return;
    }

    // Get video dimensions and rotation
    int videoWidth = _selectedVideo?.width ?? 0;
    int videoHeight = _selectedVideo?.height ?? 0;
    int videoOrientation = _selectedVideo?.orientation ?? 0;

    // Determine video orientation using enum
    ReactionVideoOrientation videoOrientationEnum =
        ReactionVideoOrientation.fromDimensions(videoWidth, videoHeight);

    print('Video dimensions: ${videoWidth}x$videoHeight');
    print('Video orientation: $videoOrientation°');
    print(
      'Video mode: ${videoOrientationEnum.label} (${videoOrientationEnum.value})',
    );

    if ((selectedFriend == null && selectedFriendEmail == null) ||
        _titleController.text.trim().isEmpty) {
      toastification.show(
        title: Text('Warning'),
        description: Text("Please fill in all fields."),
        autoCloseDuration: const Duration(seconds: 5),
        type: ToastificationType.warning,
        alignment: Alignment.bottomCenter,
      );
      setState(() {
        isLoadingSubmit = false;
      });
      return;
    }

    try {
      File? file = await _selectedVideo?.file;

      var reactionId = await createReaction({
        'user': selectedFriend?.uuid,
        'invited_to': selectedFriendEmail ?? '',
        'is_friend': true,
        'title': _titleController.text.trim(),
        'type_video': '3',
        'description': _descriptionController.text.trim(),
      });

      var uploadResult = await uploadService.uploadVideo(
        file?.path ?? '',
        'sources',
        reactionId!,
        onProgress: (sent, total) {
          setState(() {
            if (total > 0 && sent.isFinite && total.isFinite) {
              _uploadProgress = (sent / total);
            }
          });
        },
      );

      file?.delete();

      // var uploadResult = await handleUploadVideo(
      //   reactionId,
      //   videoOrientationEnum.value == 1 ? '1080x1920' : '1920x1080',
      // );
      print(uploadResult);

      print('Reaction ID: $reactionId');
      updateReaction(reactionId, {
        'video_path': 'sources/$reactionId.mp4',
        'video_duration': _duration.round(),
        'video_orientation': videoOrientationEnum.value,
      });

      createReactionVideo({
        'reaction_id': reactionId,
        'video_path': 'sources/$reactionId.mp4',
        'video_duration': _duration.round(),
        'video_orientation': videoOrientationEnum.value,
        'video_name': _selectedVideo?.title ?? file?.path.split('/').last ?? '',
        'segment': ReactionVideoSegment.sourceVideo.value,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating reaction: $e');
      toastification.show(
        title: Text('Error'),
        description: Text("There was an error creating the reaction."),
        autoCloseDuration: const Duration(seconds: 5),
        type: ToastificationType.error,
        alignment: Alignment.bottomCenter,
      );

      setState(() {
        isLoadingSubmit = false;
        _uploadProgress = 0.0;
      });
      return;
    }

    if (selectedFriend != null) {
      await updateRecentFriends(selectedFriend?.toJson());
    }

    print('Reaction sent successfully!');

    toastification.show(
      title: Text('Success'),
      description: Text("Reaction sent successfully!"),
      autoCloseDuration: const Duration(seconds: 5),
      type: ToastificationType.success,
      alignment: Alignment.bottomCenter,
    );

    clearTextFields();
    setState(() {
      isLoadingSubmit = false;
      _uploadProgress = 0.0;
    });

    // Navigate away before clearing fields to avoid widget lifecycle issues
    Navigator.of(context).pushReplacementNamed('/', arguments: {'index': 0});
  }
}
