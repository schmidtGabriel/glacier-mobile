import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:glacier/components/Button.dart';
import 'package:glacier/components/UserAvatar.dart';
import 'package:glacier/helpers/updateRecentFriends.dart';
import 'package:glacier/pages/PreviewVideoPage.dart';
import 'package:glacier/pages/UserInvite.dart';
import 'package:glacier/pages/UserList.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:glacier/services/reactions/createReaction.dart';
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
                                  if (thumb == null)
                                    return Container(color: Colors.grey);
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
                                UserAvatar(user: selectedFriend),
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
                        if (_uploadProgress > 0) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: LinearProgressIndicator(
                              value: _uploadProgress,
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Button(
                              isLoading: isLoadingSubmit,
                              loadingLabel: 'Sending...',
                              onPressed: _sendReaction,
                              label: 'Send Reaction',
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                            ),
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

  Future<void> uploadVideo() async {
    if (_selectedVideo == null) {
      toastification.show(
        title: Text('Warning'),
        description: Text("Please select a video first."),
        autoCloseDuration: const Duration(seconds: 5),
        type: ToastificationType.warning,
        alignment: Alignment.bottomCenter,
      );
      return;
    }

    File? file = await _selectedVideo?.file;
    String filePath = file?.path ?? '';

    await uploadService
        .uploadVideo(
          filePath,
          onProgress: (sent, total) {
            setState(() {
              _uploadProgress = sent / total;
            });
          },
        )
        .then((value) async {
          final file = filePath;
          _filePath = value?['filePath'] ?? '';

          setState(() {
            _uploadProgress = 0.0;
          });

          File(file).delete();

          return value;
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

    await uploadVideo();

    final videoUrl = _filePath.trim();
    final videoDuration = _duration;

    await createReaction({
      'user': selectedFriend?.uuid,
      'invited_to': selectedFriendEmail ?? '',
      'is_friend': true,
      'video': videoUrl,
      'video_duration': videoDuration,
      'title': _titleController.text.trim(),
      'type_video': '3',
      'description': _descriptionController.text.trim(),
    });

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
    });

    // Navigate away before clearing fields to avoid widget lifecycle issues
    Navigator.of(context).pushReplacementNamed('/', arguments: {'index': 0});
  }
}
