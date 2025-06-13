// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:glacier/helpers/copyAssetToFile.dart';
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

    // Test if we can write to the output directory
    // try {
    //   final testFile = File('${tempDir.path}/test.txt');
    //   await testFile.writeAsString('test');
    //   await testFile.delete();
    //   print('Directory write test: SUCCESS');
    // } catch (e) {
    //   print('Directory write test: FAILED - $e');
    //   throw Exception('Cannot write to temporary directory: $e');
    // }

    // Input files
    final watermark = await copyAssetToFile(
      'lib/assets/watermark.png',
      'watermark.png',
    );
    // final endingVideo = await copyAssetToFile(
    //   'assets/endVideo.mp4',
    //   'endVideo.mp4',
    // );

    // Final output
    // final finalOutput = '${tempDir.path}/final_video.mp4';

    // Test basic FFmpeg functionality first
    // final testOutputPath = '${tempDir.path}/test_video.mp4';
    // final testCommand =
    //     '-i "$videoPath" -c:v libx264 -preset ultrafast -t 5 -f mp4 "$testOutputPath"';

    // print('Testing basic FFmpeg with: $testCommand');
    // final testSession = await FFmpegKit.execute(testCommand);
    // final testReturnCode = await testSession.getReturnCode();
    // final testLogs = await testSession.getLogs();

    // print('Test FFmpeg return code: $testReturnCode');
    // for (final log in testLogs) {
    //   print('Test FFmpeg log: ${log.getMessage()}');
    // }

    // final testFile = File(testOutputPath);
    // print('Test output file exists: ${await testFile.exists()}');

    // if (!ReturnCode.isSuccess(testReturnCode)) {
    //   throw Exception(
    //     'Basic FFmpeg test failed with return code: $testReturnCode',
    //   );
    // }

    // // Clean up test file
    // if (await testFile.exists()) {
    //   await testFile.delete();
    // }

    // final ffmpegCommand =
    //     '-i "$localVideoPath" -i "$selfiePath" -filter_complex "[0:v]scale=1080:720:flags=bilinear[top];[1:v]scale=1080:720:flags=bilinear[bottom];color=black:size=1080x20:duration=0.1[gap];[top][gap][bottom]vstack=inputs=3:shortest=0[outv];[0:a][1:a]amix=inputs=2:duration=shortest[outa]" -map "[outv]" -map "[outa]" -c:v libx264 -preset fast -tune zerolatency -crf 18 -pix_fmt yuv420p -threads 0 -f mp4 "$stackedVideoPath"';
    //'-i "$localVideoPath" -i "$selfiePath" -filter_complex "[0:v]scale=1080:720[top];[1:v]scale=1080:720[bottom];color=black:size=1080x20:duration=0.1[gap];[top][gap][bottom]vstack=inputs=3:shortest=0" -c:v libx264 -preset ultrafast -c:a aac -b:a 128k -crf 23 -pix_fmt yuv420p -f mp4 -an "$stackedVideoPath"';

    //ffmpeg -i input.mp4 -vf "scale=-2:720,format=yuv420p" -c:v libx264 -crf 18 -preset fast -tune fastdecode -g 1 -c:a copy -movflags +faststart output.mp4

    // print('Video stacking command: $ffmpegCommand');
    // print('Input video path: $localVideoPath');
    // print('Selfie path: $selfiePath');
    // print('Output stacked video path: $stackedVideoPath');

    // final session = await FFmpegKit.execute(ffmpegCommand);
    // final returnCode = await session.getReturnCode();
    // final logs = await session.getLogs();

    // print('FFmpeg return code: $returnCode');

    // // Print all FFmpeg logs for debugging
    // for (final log in logs) {
    //   print('FFmpeg log: ${log.getMessage()}');
    // }

    // Also check if output file was created
    // final outputFile = File(stackedVideoPath);
    // print('Output file exists after command: ${await outputFile.exists()}');
    // if (await outputFile.exists()) {
    //   final fileSize = await outputFile.length();
    //   print('Output file size: $fileSize bytes');
    // }

    // if (ReturnCode.isSuccess(returnCode)) {
    // print('Stacked video saved to: $stackedVideoPath');

    // 1. Add watermark - use separate input and output files
    final watermarkCommand =
        '-i $videoPath -i $watermark -filter_complex "[1:v]scale=iw*0.3:-1[wm];[0:v][wm]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2" -codec:a copy $finalVideoPath';
    final sessionWaterMark = await FFmpegKit.execute(watermarkCommand);
    final returnCodeWaterMark = await sessionWaterMark.getReturnCode();
    final watermarkLogs = await sessionWaterMark.getLogs();

    print('Watermark command: $watermarkCommand');
    print('Input stacked video: $stackedVideoPath');
    print('Watermark file: $watermark');
    print('Final output: $finalVideoPath');

    // Print watermark FFmpeg logs for debugging
    // for (final log in watermarkLogs) {
    //   print('Watermark FFmpeg log: ${log.getMessage()}');
    // }

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

  // 2. Concat videos (with watermark + outro)
  // final concatCommand =
  //     '-i $watermarkedOutput -i $endingVideo -filter_complex "[0:v:0][0:a:0][1:v:0][1:a:0]concat=n=2:v=1:a=1[outv][outa]" -map "[outv]" -map "[outa]" $finalOutput';

  // await FFmpegKit.execute(concatCommand);

  // return finalOutput;
}
