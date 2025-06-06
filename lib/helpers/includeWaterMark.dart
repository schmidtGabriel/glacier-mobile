import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:glacier/helpers/copyAssetToFile.dart';
import 'package:path_provider/path_provider.dart';

Future<String> processVideo(String? videoPath) async {
  if (videoPath == null || videoPath.isEmpty) {
    throw Exception('Invalid video path');
  }

  final tempDir = await getTemporaryDirectory();
  print(tempDir);

  // Input files
  final watermark = await copyAssetToFile(
    'lib/assets/watermark.png',
    'watermark.png',
  );
  // final endingVideo = await copyAssetToFile(
  //   'assets/endVideo.mp4',
  //   'endVideo.mp4',
  // );
  print(watermark);

  // Intermediate file with watermark
  final watermarkedOutput = '${tempDir.path}/with_watermark.mp4';
  print(watermarkedOutput);
  // Final output
  // final finalOutput = '${tempDir.path}/final_video.mp4';

  // 1. Add watermark
  final watermarkCommand =
      '-i $videoPath -i $watermark -filter_complex "overlay=0:10" -codec:a copy $watermarkedOutput';

  await FFmpegKit.execute(watermarkCommand).then((session) async {
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      // SUCCESS
      print('success');
    } else if (ReturnCode.isCancel(returnCode)) {
      // CANCEL\
      print('cancel');
    } else {
      // ERROR
      print('error');
    }
  });

  print('Watermark added to video: $watermarkedOutput');

  return watermarkedOutput;

  // 2. Concat videos (with watermark + outro)
  // final concatCommand =
  //     '-i $watermarkedOutput -i $endingVideo -filter_complex "[0:v:0][0:a:0][1:v:0][1:a:0]concat=n=2:v=1:a=1[outv][outa]" -map "[outv]" -map "[outa]" $finalOutput';

  // await FFmpegKit.execute(concatCommand);

  // return finalOutput;
}
