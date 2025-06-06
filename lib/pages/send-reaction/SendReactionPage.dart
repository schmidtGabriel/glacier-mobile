import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:glacier/components/decorations/inputDecoration.dart';
import 'package:glacier/enums/ReactionVideoType.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:glacier/services/reactions/createReaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool isLoading = false;
  String _filePath = '';

  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _videoDurationController =
      TextEditingController();

  final TextEditingController _titleController = TextEditingController();
  String? selectedFriendId;
  String? selectedVideoType;

  final uploadService = FirebaseStorageService();

  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Reaction'),
        automaticallyImplyLeading: false,
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
                      Text(
                        "Title",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: inputDecoration("Enter title"),
                        onTapOutside: (event) {
                          FocusScope.of(context).unfocus();
                        },
                      ),
                      SizedBox(height: 16),

                      Text(
                        "Select User",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedFriendId,

                        items:
                            friends.map<DropdownMenuItem<String>>((friend) {
                              var item = friend['invited_user'];
                              return DropdownMenuItem<String>(
                                value: item['uuid'],
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: Text(item['name']),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedFriendId = value;
                          });
                        },
                        decoration: inputDecoration("Choose a friend"),
                      ),
                      SizedBox(height: 16),

                      Text(
                        "Video Type",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        value: selectedVideoType,
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

                      if (selectedVideoType == "3") ...[
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.video,
                            );

                            if (result != null &&
                                result.files.single.path != null) {
                              _filePath = result.files.single.path!;
                              await uploadService
                                  .uploadVideo(
                                    result.files.single.path!,
                                    onProgress: (sent, total) {
                                      setState(() {
                                        _uploadProgress = sent / total;
                                      });
                                    },
                                  )
                                  .then((value) async {
                                    final filePath = result.files.single.path!;
                                    _videoUrlController.text =
                                        'videos/${result.files.single.name}';

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
                                    setState(() {
                                      _uploadProgress = 0.0;
                                    });

                                    File(_filePath).delete();
                                  });
                            }
                          },
                          icon: Icon(Icons.upload),
                          label: Text("Upload Video"),
                        ),
                      ],

                      if (_uploadProgress > 0) ...[
                        SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                          ),
                        ),
                      ],

                      SizedBox(height: 16),

                      Text(
                        "Video Path",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      SizedBox(height: 8),

                      TextField(
                        controller: _videoUrlController,
                        readOnly: selectedVideoType == "3" ? true : false,
                        decoration: inputDecoration(
                          "Video URL",
                        ).copyWith(hintText: "Path of uploaded video"),
                      ),
                      SizedBox(height: 16),

                      Text(
                        "Video Duration",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      SizedBox(height: 8),

                      TextField(
                        controller: _videoDurationController,
                        readOnly: selectedVideoType == "3" ? true : false,
                        decoration: inputDecoration(
                          "Video Duration",
                        ).copyWith(hintText: "Duration in seconds"),
                      ),

                      SizedBox(height: 16),

                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _sendReaction,

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: const Text(
                                'Submit Reaction',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
      ),
    );
  }

  clearTextFields() {
    setState(() {
      _videoUrlController.clear();
      _videoDurationController.clear();
      _titleController.clear();
      selectedFriendId = null;
      selectedVideoType = null;
    });
  }

  @override
  void dispose() {
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
    final prefs = await SharedPreferences.getInstance();
    friends = jsonDecode(prefs.getString('friends') ?? '[]') as List;

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
      'user': selectedFriendId,
      'url': videoUrl,
      'video_duration': videoDuration,
      'title': _titleController.text.trim(),
      'type_video': selectedVideoType,
    });

    clearTextFields();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Reaction sent successfully!")));
  }
}
