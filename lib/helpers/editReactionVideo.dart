// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:glacier/helpers/addWatermark.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> processVideo(
  String? videoPath,
  String? selfiePath,
  String uuid,
) async {
  try {
    // Validate input paths
    if (videoPath == null ||
        videoPath.isEmpty ||
        selfiePath == null ||
        selfiePath.isEmpty) {
      throw Exception('Invalid video path');
    } // Check if input files exist
    final selfieFile = File(selfiePath);

    print('Selfie file path: $selfiePath');
    print('Video file path: $videoPath');

    // Handle URL vs local file for video
    // String localVideoPath = videoPath;
    // if (videoPath.startsWith('http://') || videoPath.startsWith('https://')) {
    //   print('Video is a URL, downloading: $videoPath');

    //   final tempDir = await getTemporaryDirectory();
    //   localVideoPath = '${tempDir.path}/downloaded_video.mov';

    //   try {
    //     final response = await http.get(Uri.parse(videoPath));
    //     if (response.statusCode == 200) {
    //       final downloadedFile = File(localVideoPath);
    //       await downloadedFile.writeAsBytes(response.bodyBytes);
    //       print('Video downloaded successfully to: $localVideoPath');
    //     } else {
    //       throw Exception('Failed to download video: ${response.statusCode}');
    //     }
    //   } catch (e) {
    //     throw Exception('Error downloading video: $e');
    //   }
    // }

    // final actualVideoFile = File(localVideoPath);

    // print('Checking video file: $localVideoPath');
    // print('Video file exists: ${await actualVideoFile.exists()}');
    // print('Checking selfie file: $selfiePath');
    // print('Selfie file exists: ${await selfieFile.exists()}');

    // if (!await actualVideoFile.exists()) {
    //   throw Exception('Video file does not exist: $localVideoPath');
    // }

    if (!await selfieFile.exists()) {
      throw Exception('Selfie file does not exist: $selfiePath');
    }

    final tempDir = await getTemporaryDirectory();

    // Ensure the temporary directory exists
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
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

    var sessionWaterMark = await addWatermarkWithDate(
      videoPath: videoPath,
      outputPath: finalVideoPath,
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
