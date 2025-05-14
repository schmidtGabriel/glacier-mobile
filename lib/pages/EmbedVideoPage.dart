import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_truereaction/components/CameraPreviewWidget.dart';
import 'package:video_player/video_player.dart';

class EmbedVideoPage extends StatefulWidget {
  final String? uuid;
  const EmbedVideoPage({super.key, this.uuid});

  @override
  State<EmbedVideoPage> createState() => _EmbedVideoPageState();
}

class _EmbedVideoPageState extends State<EmbedVideoPage> {
  bool isRecording = false;
  int countdown = 3;
  bool startCountdown = false;
  bool showCamera = false;

  String? videoPath;

  VideoPlayerController? _controllerRecording;
  VideoPlayerController? _controllerVideo;

  Map<String, dynamic>? currentReaction;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    final videoEmbed =
        'https://www.tiktok.com/@kbsviews/video/7498697625936366891';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Embed Video'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controllerVideo != null && _controllerVideo!.value.isInitialized)
            AspectRatio(
              aspectRatio: _controllerVideo!.value.aspectRatio,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controllerVideo!.value.size.width,
                    height: _controllerVideo!.value.size.height,
                    child: HtmlWidget(
                      '''
                        <iframe width="100" height="200"
                          src="$videoEmbed"
                          title="" frameborder="0"
                          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                          referrerpolicy="strict-origin-when-cross-origin"
                          allowfullscreen></iframe>
                      ''',
                      customStylesBuilder: (element) {
                        return {
                          'background-color': 'black',
                          'width': '${width}px',
                          'height': '${height}px',
                        };
                      },
                    ),
                  ),
                ),
              ),
            )
          else
            Center(child: CircularProgressIndicator()),

          // Camera preview in bottom right
          Visibility(
            visible: showCamera,
            child: Positioned(
              bottom: 20,
              right: 20,
              child: CameraPreviewWidget(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadReactionByUuid();
  }

  // Load reaction by UUID
  Future<bool> _loadReactionByUuid() async {
    final prefs = await SharedPreferences.getInstance();

    final reactionsString = prefs.getString('reactions');
    if (reactionsString == null) {
      return false;
    }
    final List<dynamic> reactionsList = jsonDecode(reactionsString);

    final reaction = reactionsList.firstWhere(
      (item) => item['uuid'] == widget.uuid,
      orElse: () => null,
    );
    if (reaction != null) {
      setState(() {
        currentReaction = Map<String, dynamic>.from(reaction);
      });
      // await _initializeVideo();

      return true;
    }
    return false; // Return false if no reaction is found
  }
}
