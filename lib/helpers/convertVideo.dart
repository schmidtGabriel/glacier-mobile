import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:glacier/helpers/isVideoLandscape.dart';

// Convert video using Device and FFmpeg
Future<FFmpegSession> convertVideo({
  required String videoPath,
  required String outputPath,
  Function(double)? onProgress,
}) async {
  // Parse the output to get width and height
  // You might want to add proper JSON parsing here
  bool isLandscape = await isVideoLandscape(videoPath);

  print('Video is landscape: $isLandscape');
  String scaleFilter;
  if (isLandscape) {
    // For landscape videos, scale to 720 height, auto-calculate width
    scaleFilter = 'scale=-1:720';
  } else {
    // For portrait videos, scale to 720 width, auto-calculate height
    scaleFilter = 'scale=720:-1';
  }

  final command =
      '-i $videoPath '
      '-vf "$scaleFilter,fps=30,format=yuv420p" '
      '-c:v libx264 -preset veryfast -crf 23 '
      '-c:a aac -b:a 128k '
      '$outputPath';

  // Start fake progress if callback is provided
  if (onProgress != null) {
    _simulateProgress(onProgress);
  }

  var result = await FFmpegKit.execute(command);

  if (onProgress != null) {
    onProgress(1.0);
  }

  return result;
}

void _simulateProgress(Function(double) onProgress) {
  // Simulate progress updates in background
  Future.delayed(Duration.zero, () async {
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 200));
      onProgress(i / 100.0); // Progress from 0.0 to 1.0
      if (i == 90) break;
    }
  });
}
