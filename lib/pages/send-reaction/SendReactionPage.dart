import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:glacier/components/decorations/inputDecoration.dart';
import 'package:glacier/enums/ReactionVideoType.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:glacier/services/createReaction.dart';
import 'package:video_player/video_player.dart';

class SendReactionPage extends StatefulWidget {
  const SendReactionPage({super.key});

  @override
  State<SendReactionPage> createState() => _SendReactionPageState();
}

class _SendReactionPageState extends State<SendReactionPage> {
  String? uuid;
  String? email;
  String? name;
  List friends = [];
  bool isLoading = true;

  final _friendEmailController = TextEditingController();

  final List<String> _invitedFriends = [];

  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _videoDurationController =
      TextEditingController();

  final TextEditingController _titleController = TextEditingController();
  String? selectedFriendId;
  String? selectedVideoType;

  final uploadService = FirebaseStorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Send Reaction')),
      body: SafeArea(
        child:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Title",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: inputDecoration("Enter title"),
                      ),
                      SizedBox(height: 16),

                      Text(
                        "Select User",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        items:
                            friends.map<DropdownMenuItem<String>>((friend) {
                              return DropdownMenuItem<String>(
                                value: friend['id'],
                                child: Text(friend['name']),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedFriendId = value;
                          });
                        },
                        decoration: inputDecoration("Choose a user"),
                      ),
                      SizedBox(height: 16),

                      Text(
                        "Video Type",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        items:
                            ReactionVideoType.map((type) {
                              return DropdownMenuItem(
                                value: type['value'].toString(),
                                child: Text(type['label'] as String),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedVideoType = value;
                          });
                        },
                        decoration: inputDecoration("Select video type"),
                      ),
                      SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.video,
                          );

                          if (result != null &&
                              result.files.single.path != null) {
                            uploadService
                                .uploadVideo(result.files.single.path!)
                                .then((value) async {
                                  final filePath = result.files.single.path!;
                                  _videoUrlController.text = filePath;

                                  final videoController =
                                      VideoPlayerController.file(
                                        File(filePath),
                                      );
                                  await videoController.initialize();
                                  final duration =
                                      videoController.value.duration;
                                  _videoDurationController.text =
                                      "${duration.inSeconds}s";
                                  videoController.dispose();
                                });
                          }
                        },
                        icon: Icon(Icons.upload),
                        label: Text("Upload Video"),
                      ),
                      SizedBox(height: 16),

                      TextField(
                        controller: _videoUrlController,
                        readOnly: true,
                        decoration: inputDecoration(
                          "Video URL",
                        ).copyWith(hintText: "Path of uploaded video"),
                      ),
                      SizedBox(height: 16),

                      TextField(
                        controller: _videoDurationController,
                        readOnly: true,
                        decoration: inputDecoration(
                          "Video Duration",
                        ).copyWith(hintText: "Duration in seconds"),
                      ),

                      SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: _sendReaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  @override
  void dispose() {
    _friendEmailController.dispose();
    _videoUrlController.dispose();
    _videoDurationController.dispose();
    _titleController.dispose();
    super.dispose();
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

  Future<void> _sendReaction() async {
    final videoUrl = _videoUrlController.text.trim();
    final videoDuration = _videoDurationController.text.trim();

    if (videoUrl.isEmpty || videoDuration.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please upload a video first.")));
      return;
    }

    if (selectedFriendId == null ||
        selectedVideoType == null ||
        _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill in all fields.")));
      return;
    }

    await createReaction({
      'userId': selectedFriendId,
      'videoUrl': videoUrl,
      'videoDuration': videoDuration,
      'title': _titleController.text.trim(),
      'videoType': selectedVideoType,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Reaction sent successfully!")));
  }
}
