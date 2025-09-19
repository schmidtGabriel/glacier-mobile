import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glacier/components/Button.dart';
import 'package:glacier/components/FriendAutocomplete.dart';
import 'package:glacier/components/VideoThumbnailWidget.dart';
import 'package:glacier/enums/ReactionVideoOrientation.dart';
import 'package:glacier/enums/ReactionVideoSegment.dart';
import 'package:glacier/helpers/ToastHelper.dart';
import 'package:glacier/helpers/updateRecentFriends.dart';
import 'package:glacier/pages/PreviewVideoPage.dart';
import 'package:glacier/pages/send-reaction/GalleryScreen.dart';
import 'package:glacier/resources/FriendResource.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:glacier/services/reactions/createReaction.dart';
import 'package:glacier/services/reactions/createReactionVideo.dart';
import 'package:glacier/services/reactions/updateReaction.dart';
import 'package:glacier/themes/app_colors.dart';
import 'package:glacier/themes/theme_extensions.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

//  ReactionStatusEnum {
//   Hold = -1,
//   Pending = 0,
//   Sent = 1,
//   Approved = 10,
//   Rejected = -10,
// }

class SendReactionPage extends StatefulWidget {
  final UserResource? sendTo;
  final int duration;

  const SendReactionPage({super.key, this.sendTo, this.duration = 0});

  @override
  State<SendReactionPage> createState() => _SendReactionPageState();
}

class _SendReactionPageState extends State<SendReactionPage> {
  String? uuid;
  String? email;
  String? name;

  bool isLoading = false;
  bool isLoadingSubmit = false;
  String _filePath = '';
  int _duration = 0;
  String userId = '';

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _controllerFriend = TextEditingController();

  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  UserResource? selectedFriend;
  String? selectedFriendEmail;
  String? selectedVideoType;
  AssetEntity? _selectedVideo;
  String _fileName = '';

  List<FriendResource> friends = [];
  List<FriendResource> filteredFriends = [];

  final uploadService = FirebaseStorageService();

  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Send Reaction'),
          elevation: 0,
          leading: CloseButton(
            onPressed: () {
              final confirmDiscart = AlertDialog(
                title: const Text('Discard Reaction?'),
                content: const Text(
                  'Are you sure you want to discard this reaction?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Discard'),
                  ),
                ],
              );
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return confirmDiscart;
                },
              ).then((value) {
                if (value == true) {
                  clearTextFields();
                  Navigator.of(
                    context,
                  ).pushReplacementNamed('/', arguments: {'index': 0});
                }
              });
            },
          ),
        ),

        body: SafeArea(
          child:
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Title",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            focusNode: _titleFocusNode,
                            autofocus: false,
                            decoration: InputDecoration(
                              labelText: "Enter title",
                            ),
                            onTapOutside: (event) {
                              FocusScope.of(context).unfocus();
                              _titleFocusNode.unfocus();
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,

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
                            minLines: 2,
                            maxLines: 6,
                            autofocus: false,
                            controller: _descriptionController,
                            focusNode: _descriptionFocusNode,

                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,

                            decoration: InputDecoration(
                              labelText: "Enter description",
                            ),
                            onTapOutside: (event) {
                              FocusScope.of(context).unfocus();
                              _descriptionFocusNode.unfocus();
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          Text(
                            "Send to",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          SizedBox(height: 8),

                          FriendAutocomplete(
                            value: selectedFriend,
                            controller: _controllerFriend,
                            formKey: _formKey,
                            onFriendSelected: (friend) {
                              setState(() {
                                selectedFriend = friend;
                                selectedFriendEmail = null;
                              });
                            },
                            onNewFriendCreated: (name, email) async {
                              setState(() {
                                selectedFriend = null;
                                selectedFriendEmail = email;
                              });
                            },

                            hintText: 'Select a friend to send reaction...',
                          ),

                          SizedBox(height: 16),

                          Text(
                            "Video Source",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          SizedBox(height: 8),

                          if (_selectedVideo != null) ...[
                            VideoThumbnailWidget(
                              videoPath: _filePath,

                              onTap: () async {
                                await Navigator.push<void>(
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
                            ),
                            SizedBox(height: 8),
                            Center(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _fileName,
                                      overflow: TextOverflow.ellipsis,

                                      style: TextStyle(
                                        color:
                                            context.isDarkMode
                                                ? Colors.grey.shade300
                                                : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.change_circle_outlined),
                                    onPressed: () {
                                      _handlePickVideo();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                          ] else ...[
                            GestureDetector(
                              onTap: () async {
                                FocusScope.of(context).unfocus();

                                _handlePickVideo();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,

                                  border: Border.all(
                                    color:
                                        context.isDarkMode
                                            ? AppColors.secondaryLight
                                            : AppColors.secondary,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 10,
                                  children: [
                                    Text(
                                      'Upload Video',
                                      style: TextStyle(
                                        color:
                                            context.isDarkMode
                                                ? AppColors.secondaryLight
                                                : AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(
                                      Icons.camera_alt_outlined,
                                      color:
                                          context.isDarkMode
                                              ? AppColors.secondaryLight
                                              : AppColors.secondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: 20),

                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : Button(
                                isLoading: isLoadingSubmit,
                                loadingLabel:
                                    '${(_uploadProgress * 100).toStringAsFixed(0)}% Sending...',
                                onPressed: _sendReaction,
                                label: 'Send Reaction',
                              ),

                          if (_uploadProgress > 0) ...[
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: LinearProgressIndicator(
                                value: _uploadProgress,
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
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
  }

  _handlePickVideo() async {
    setState(() {
      _selectedVideo = null;
      _duration = 0;
      _filePath = '';
      _fileName = '';
    });

    final selectedVideo = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(builder: (context) => GalleryScreen()),
    );
    if (selectedVideo != null && mounted) {
      final video = selectedVideo['video'] as AssetEntity?;
      final duration = selectedVideo['duration'] ?? 0;
      final file = await video?.file;
      final filePath = file?.path ?? '';
      final fileName = file?.path.split('/').last ?? '';

      setState(() {
        _selectedVideo = video;
        _duration = duration;
        _filePath = filePath;
        _fileName = fileName;
      });
    }
  }

  Future<void> _sendReaction() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_selectedVideo == null) {
      ToastHelper.showWarning(
        context,
        description: 'Please select a video to send.',
      );

      return;
    }

    setState(() {
      isLoadingSubmit = true;
    });

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
      ToastHelper.showWarning(
        context,
        description: 'Please select a friend and enter a title.',
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

      final res = await uploadService.uploadVideo(
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
      print('Upload result: $res');
      if (res != null) {
        file?.delete();

        // print('Reaction ID: $reactionId');
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
          'video_name': _fileName ?? '',
          'segment': ReactionVideoSegment.sourceVideo.value,
          'created_at': DateTime.now().toIso8601String(),
        });

        if (selectedFriend != null) {
          await updateRecentFriends(selectedFriend?.toJson());
        }

        ToastHelper.showSuccess(
          context,
          description: 'Reaction sent successfully!',
        );

        clearTextFields();
        setState(() {
          isLoadingSubmit = false;
          _uploadProgress = 0.0;
        });

        // Navigate away before clearing fields to avoid widget lifecycle issues
        Navigator.of(
          context,
        ).pushReplacementNamed('/', arguments: {'index': 0});
      } else {
        updateReaction(reactionId, {'status': '-10'});
        return;
      }
    } catch (e) {
      print('Error creating reaction: $e');
      ToastHelper.showError(
        context,
        description: "There was an error creating the reaction.",
      );

      setState(() {
        isLoadingSubmit = false;
        _uploadProgress = 0.0;
      });
      return;
    }
  }
}
