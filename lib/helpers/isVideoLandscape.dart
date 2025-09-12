import 'dart:convert';

import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';

Future<bool> isVideoLandscape(String videoPath) async {
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
