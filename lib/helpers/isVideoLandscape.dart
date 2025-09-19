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

        // Print additional video metadata
        print('=== Video Metadata ===');
        print('Codec: ${videoStream['codec_name'] ?? 'Unknown'}');
        print('Pixel format: ${videoStream['pix_fmt'] ?? 'Unknown'}');
        print('Duration: ${videoStream['duration'] ?? 'Unknown'} seconds');
        print('Frame rate: ${videoStream['r_frame_rate'] ?? 'Unknown'}');
        print('Bit rate: ${videoStream['bit_rate'] ?? 'Unknown'} bps');
        print('Profile: ${videoStream['profile'] ?? 'Unknown'}');
        print('Level: ${videoStream['level'] ?? 'Unknown'}');

        // Print tags metadata if available
        if (tags != null && tags.isNotEmpty) {
          print('=== Tags Metadata ===');
          tags.forEach((key, value) {
            print('$key: $value');
          });
        }

        // Print side data information if available
        if (sideDataList != null && sideDataList.isNotEmpty) {
          print('=== Side Data ===');
          for (var sideData in sideDataList) {
            print('Type: ${sideData['side_data_type']}');
            sideData.forEach((key, value) {
              if (key != 'side_data_type') {
                print('  $key: $value');
              }
            });
          }
        }

        // Print disposition information
        final disposition = videoStream['disposition'];
        if (disposition != null) {
          print('=== Disposition ===');
          disposition.forEach((key, value) {
            if (value == 1) {
              print('$key: enabled');
            }
          });
        }

        print('=====================');

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
