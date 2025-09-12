// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:glacier/helpers/makeFinalVideo.dart';
import 'package:glacier/resources/ReactionResource.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// This method will send the selfie to server and return the path of the processed video

Future<String?> processVideo(ReactionResource? reaction) async {
  try {
    var videoUrl = reaction?.videoUrl ?? '';
    var reactionUrl = reaction?.reactionUrl ?? '';
    var uuid = reaction?.uuid ?? '';
    var delay = reaction?.delayDuration ?? 0;

    print('Original video path: $videoUrl');
    print('Original selfie path: $reactionUrl');

    final tempDir = await getTemporaryDirectory();

    // Ensure the temporary directory exists
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }

    String localVideoPath = videoUrl;
    String localSelfiePath = reactionUrl;

    // Download video if it's a URL
    if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
      print('Video is a URL, downloading: $videoUrl');

      localVideoPath = '${tempDir.path}/downloaded_video.mp4';

      try {
        final response = await http.get(Uri.parse(videoUrl));
        if (response.statusCode == 200) {
          final downloadedFile = File(localVideoPath);
          await downloadedFile.writeAsBytes(response.bodyBytes);
          print('Video downloaded successfully to: $localVideoPath');
        } else {
          throw Exception('Failed to download video: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error downloading video: $e');
      }
    }

    // Download selfie if it's a URL
    if (reactionUrl.startsWith('http://') ||
        reactionUrl.startsWith('https://')) {
      print('Selfie is a URL, downloading: $reactionUrl');

      localSelfiePath = '${tempDir.path}/downloaded_selfie.mp4';

      try {
        final response = await http.get(Uri.parse(reactionUrl));
        if (response.statusCode == 200) {
          final downloadedFile = File(localSelfiePath);
          await downloadedFile.writeAsBytes(response.bodyBytes);
          print('Selfie downloaded successfully to: $localSelfiePath');
        } else {
          throw Exception('Failed to download selfie: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error downloading selfie: $e');
      }
    }

    // Check if files exist after download
    final videoFile = File(localVideoPath);
    final selfieFile = File(localSelfiePath);

    print('Checking video file: $localVideoPath');
    print('Video file exists: ${await videoFile.exists()}');
    print('Checking selfie file: $localSelfiePath');
    print('Selfie file exists: ${await selfieFile.exists()}');

    if (!await videoFile.exists()) {
      throw Exception('Video file does not exist: $localVideoPath');
    }

    if (!await selfieFile.exists()) {
      throw Exception('Selfie file does not exist: $localSelfiePath');
    }

    final stackedVideoPath = '${tempDir.path}/stacked_video.mp4';
    final finalVideoPath = '${tempDir.path}/$uuid.mp4';

    // Clean up any existing files
    final stackedFile = File(stackedVideoPath);
    final finalFile = File(finalVideoPath);
    if (await stackedFile.exists()) {
      await stackedFile.delete();
    }
    if (await finalFile.exists()) {
      await finalFile.delete();
    }

    var sessionWaterMark = await makeFinalVideo(
      videoPath: localVideoPath, // Use local downloaded path
      selfiePath: localSelfiePath, // Use local downloaded path
      outputPath: finalVideoPath,
      delay: delay,
    );

    final returnCodeWaterMark = await sessionWaterMark.getReturnCode();

    print('Input stacked video: $stackedVideoPath');
    print('Final output: $finalVideoPath');

    if (ReturnCode.isSuccess(returnCodeWaterMark)) {
      // SUCCESS
      print('success');
      return finalVideoPath;
    } else if (ReturnCode.isCancel(returnCodeWaterMark)) {
      // CANCEL\
      print('cancel');
      return null;
    } else {
      // ERROR
      print('error');
      return null;
    }
    // } else {
    //   print('Failed to stack videos. Return code: $returnCode');
    //   return null;
    // }
  } catch (e) {
    print('Error stacking videos: $e');
    return null;
  }
}
