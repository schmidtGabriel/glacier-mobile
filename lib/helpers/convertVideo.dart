import 'dart:convert';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';

Future<FFmpegSession> convertVideo({
  required String videoPath,
  required String outputPath,
}) async {
  // Parse the output to get width and height
  // You might want to add proper JSON parsing here
  bool isLandscape = await _isVideoLandscape(videoPath);

  print('Video is landscape: $isLandscape');
  String scaleFilter;
  if (isLandscape) {
    // For landscape videos, scale to 1920x1080
    scaleFilter = 'scale=1920:1080';
  } else {
    // For portrait videos, scale to 1080x1920
    scaleFilter = 'scale=1080:1920';
  }

  final command =
      '-i $videoPath '
      '-vf "$scaleFilter,fps=30,format=yuv420p" '
      '-c:v libx264 -preset veryfast -crf 23 '
      '-c:a aac -b:a 128k '
      '$outputPath';

  var result = await FFmpegKit.execute(command);

  return result;
}

Future<bool> _isVideoLandscape(String videoPath) async {
  final session = await FFprobeKit.execute(
    '-v quiet -print_format json -show_streams -select_streams v:0 "$videoPath"',
  );
  final output = await session.getOutput();

  if (output != null && output.isNotEmpty) {
    try {
      final jsonData = json.decode(output);
      final streams = jsonData['streams'] as List;
      if (streams.isNotEmpty) {
        final videoStream = streams[0];
        int width = videoStream['width'] as int? ?? 0;
        int height = videoStream['height'] as int? ?? 0;

        // Check for rotation metadata in multiple places
        final tags = videoStream['tags'] as Map<String, dynamic>?;
        final sideDataList = videoStream['side_data_list'] as List?;
        int rotation = 0;

        // Check rotation in tags
        if (tags != null) {
          final rotateValue = tags['rotate'];
          if (rotateValue != null) {
            rotation = int.tryParse(rotateValue.toString()) ?? 0;
          }
        }

        // Check rotation in side_data_list (common for mobile videos)
        if (sideDataList != null) {
          for (var sideData in sideDataList) {
            if (sideData['side_data_type'] == 'Display Matrix') {
              final rotationValue = sideData['rotation'];
              if (rotationValue != null) {
                rotation =
                    (double.tryParse(rotationValue.toString()) ?? 0)
                        .round()
                        .abs();
                break;
              }
            }
          }
        }

        print('Raw video dimensions: ${width}x$height');
        print('Rotation metadata: $rotation degrees');
        print('Tags: $tags');
        print('Side data: $sideDataList');

        // If video is rotated 90 or 270 degrees, swap width and height
        if (rotation == 90 || rotation == 270) {
          final temp = width;
          width = height;
          height = temp;
          print('Adjusted dimensions after rotation: ${width}x$height');
        }

        return width > height;
      }
    } catch (e) {
      print('Error parsing video dimensions: $e');
    }
  }

  return false; // Default to portrait if unable to determine
}
