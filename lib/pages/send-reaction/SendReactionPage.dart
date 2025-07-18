import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:glacier/components/decorations/inputDecoration.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:glacier/services/reactions/createReaction.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

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
  int _duration = 0;
  String userId = '';

  final TextEditingController _videoDurationController =
      TextEditingController();

  final TextEditingController _titleController = TextEditingController();
  String? selectedFriendId;
  String? selectedVideoType;
  AssetEntity? _selectedVideo;

  final uploadService = FirebaseStorageService();

  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
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
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pushNamed(
                                          '/preview-video',
                                          arguments: {
                                            'localVideo': _selectedVideo,
                                            'hasConfirmButton': false,
                                          },
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
                                if (item['uuid'] == userId) {
                                  item = friend['requested_user'];
                                }

                                return DropdownMenuItem<String>(
                                  value: item['uuid'].toString(),
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

                        // if (selectedVideoType == "3") ...[
                        //   SizedBox(height: 16),
                        //   ElevatedButton.icon(
                        //     onPressed: () async {
                        //       final result = await FilePicker.platform
                        //           .pickFiles(type: FileType.video);

                        //       if (result != null &&
                        //           result.files.single.path != null) {
                        //         await uploadService
                        //             .uploadVideo(
                        //               result.files.single.path!,
                        //               onProgress: (sent, total) {
                        //                 setState(() {
                        //                   _uploadProgress = sent / total;
                        //                 });
                        //               },
                        //             )
                        //             .then((value) async {
                        //               final file = result.files.single.path!;
                        //               _filePath =
                        //                   'videos/${result.files.single.name}';

                        //               _videoUrlController
                        //                   .text = await FirebaseStorageService()
                        //                   .getDownloadUrl(_filePath);

                        //               final videoController =
                        //                   VideoPlayerController.file(
                        //                     File(result.files.single.path!),
                        //                   );
                        //               await videoController.initialize();

                        //               _duration =
                        //                   videoController
                        //                       .value
                        //                       .duration
                        //                       .inSeconds;
                        //               _videoDurationController.text =
                        //                   "${_duration}s";

                        //               videoController.dispose();
                        //               setState(() {
                        //                 _uploadProgress = 0.0;
                        //               });

                        //               File(file).delete();
                        //             });
                        //       }
                        //     },
                        //     icon: Icon(Icons.upload),
                        //     label: Text("Upload Video"),
                        //   ),
                        // ],
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
      ),
    );
  }

  clearTextFields() {
    setState(() {
      _videoDurationController.clear();
      _titleController.clear();
      _selectedVideo = null;
      _filePath = '';
      _duration = 0;
      isLoading = false;
      selectedFriendId = null;
      selectedVideoType = null;
    });
  }

  @override
  void dispose() {
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
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final user = jsonDecode(userJson);
      userId = user['uuid'] ?? '';
    }

    SharedPreferences.getInstance().then((prefs) {
      var friendId = prefs.getString('request_user');

      if (friendId != null) {
        selectedFriendId = friendId;
        prefs.remove('request_user');
      }
    });

    Future.delayed(Duration(seconds: 3));
    setState(() {
      isLoading = false;
    });

    final videoPath = await Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/gallery');

    if (videoPath != null) {
      _selectedVideo = videoPath as AssetEntity?;
      final file = await (videoPath as AssetEntity).file;
      setState(() {
        _videoDurationController.text = '${_selectedVideo?.duration}s' ?? '0s';
        _duration = _selectedVideo?.duration ?? 0;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
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
    await uploadVideo();

    final videoUrl = _filePath.trim();
    final videoDuration = _duration;

    if (videoUrl.isEmpty) {
      toastification.show(
        title: Text('Warning'),
        description: Text("Please upload a video first."),
        autoCloseDuration: const Duration(seconds: 5),
        type: ToastificationType.warning,
        alignment: Alignment.bottomCenter,
      );

      return;
    }

    if (selectedFriendId == null || _titleController.text.trim().isEmpty) {
      toastification.show(
        title: Text('Warning'),
        description: Text("Please fill in all fields."),
        autoCloseDuration: const Duration(seconds: 5),
        type: ToastificationType.warning,
        alignment: Alignment.bottomCenter,
      );

      return;
    }
    await createReaction({
      'user': selectedFriendId,
      'invited_email': 'g.avilasouza@gmail.com',
      'is_friend': true,
      'video': videoUrl,
      'video_duration': videoDuration,
      'title': _titleController.text.trim(),
      'type_video': '3',
    });
    print('Reaction sent successfully!');

    clearTextFields();
    toastification.show(
      title: Text('Success'),
      description: Text("Reaction sent successfully!"),
      autoCloseDuration: const Duration(seconds: 5),
      type: ToastificationType.success,
      alignment: Alignment.bottomCenter,
    );
  }
}
