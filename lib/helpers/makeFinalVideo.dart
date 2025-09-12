import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:glacier/helpers/isVideoLandscape.dart';
import 'package:intl/intl.dart';

String getFormattedText() {
  final now = DateTime.now();
  final formatted =
      'Glacier - Verified reaction | ${DateFormat("MMM d h:mm a").format(now)}';
  return formatted
      .replaceAll('\\', '\\\\') // escape backslashes
      .replaceAll(':', '\\:') // escape colons
      .replaceAll('|', '\\|') // escape pipes
      .replaceAll("'", "\\'"); // escape single quotes
}

Future<FFmpegSession> makeFinalVideo({
  required String videoPath,
  required String selfiePath,
  required String outputPath,
  required int delay,
}) async {
  final text = getFormattedText();

  bool isLandscape = await isVideoLandscape(videoPath);
  bool useBlurredBackground = true;

  // Create vertical stack with appropriate proportions and delay
  String stackFilter;

  if (isLandscape) {
    print('Video is landscape oriented');
    // For landscape video: 35% space for main video, 65% for selfie
    if (useBlurredBackground) {
      stackFilter =
          '[0:v]tpad=start_duration=${delay}s:start_mode=clone[v0_delayed]; '
          // Split the delayed video stream for dual use
          '[v0_delayed]split=2[v0_for_bg][v0_for_scale]; '
          // Create blurred background from first frame of main video
          '[v0_for_bg]scale=720:405:force_original_aspect_ratio=increase:force_divisible_by=2,crop=720:405,gblur=sigma=15[v0_bg]; '
          // Scale main video for overlay
          '[v0_for_scale]scale=720:405:force_original_aspect_ratio=decrease:force_divisible_by=2[v0_scaled]; '
          '[v0_bg][v0_scaled]overlay=(W-w)/2:(H-h)/2[v0]; '
          // Split selfie stream for dual use
          '[1:v]split=2[v1_for_bg][v1_for_scale]; '
          // Create blurred background from first frame of selfie
          '[v1_for_bg]scale=720:753:force_original_aspect_ratio=increase:force_divisible_by=2,crop=720:753,gblur=sigma=15[v1_bg]; '
          // Scale selfie for overlay
          '[v1_for_scale]scale=720:753:force_original_aspect_ratio=decrease:force_divisible_by=2[v1_scaled]; '
          '[v1_bg][v1_scaled]overlay=(W-w)/2:(H-h)/2[v1]; '
          '[v0][v1]vstack=inputs=2[stacked]';
    } else {
      stackFilter =
          '[0:v]tpad=start_duration=${delay}s:start_mode=clone[v0_delayed]; '
          '[v0_delayed]scale=720:405:force_original_aspect_ratio=decrease:force_divisible_by=2[v0_scaled]; '
          '[v0_scaled]pad=720:405:(ow-iw)/2:(oh-ih)/2:black[v0]; '
          '[1:v]scale=720:753:force_original_aspect_ratio=decrease:force_divisible_by=2[v1_scaled]; '
          '[v1_scaled]pad=720:753:(ow-iw)/2:(oh-ih)/2:black[v1]; '
          '[v0][v1]vstack=inputs=2[stacked]';
    }
  } else {
    print('Video is portrait oriented');
    // For portrait video: 50% space for each video (equal split)
    if (useBlurredBackground) {
      stackFilter =
          '[0:v]tpad=start_duration=${delay}s:start_mode=clone[v0_delayed]; '
          // Split the delayed video stream for dual use
          '[v0_delayed]split=2[v0_for_bg][v0_for_scale]; '
          // Create blurred background from first frame of main video
          '[v0_for_bg]scale=720:640:force_original_aspect_ratio=increase:force_divisible_by=2,crop=720:640,gblur=sigma=15[v0_bg]; '
          // Scale main video for overlay
          '[v0_for_scale]scale=720:640:force_original_aspect_ratio=decrease:force_divisible_by=2[v0_scaled]; '
          '[v0_bg][v0_scaled]overlay=(W-w)/2:(H-h)/2[v0]; '
          // Split selfie stream for dual use
          '[1:v]split=2[v1_for_bg][v1_for_scale]; '
          // Create blurred background from first frame of selfie
          '[v1_for_bg]scale=720:640:force_original_aspect_ratio=increase:force_divisible_by=2,crop=720:640,gblur=sigma=15[v1_bg]; '
          // Scale selfie for overlay
          '[v1_for_scale]scale=720:640:force_original_aspect_ratio=decrease:force_divisible_by=2[v1_scaled]; '
          '[v1_bg][v1_scaled]overlay=(W-w)/2:(H-h)/2[v1]; '
          '[v0][v1]vstack=inputs=2[stacked]';
    } else {
      stackFilter =
          '[0:v]tpad=start_duration=${delay}s:start_mode=clone[v0_delayed]; '
          '[v0_delayed]scale=720:640:force_original_aspect_ratio=decrease:force_divisible_by=2[v0_scaled]; '
          '[v0_scaled]pad=720:640:(ow-iw)/2:(oh-ih)/2:black[v0]; '
          '[1:v]scale=720:640:force_original_aspect_ratio=decrease:force_divisible_by=2[v1_scaled]; '
          '[v1_scaled]pad=720:640:(ow-iw)/2:(oh-ih)/2:black[v1]; '
          '[v0][v1]vstack=inputs=2[stacked]';
    }
  }

  // Combine the stack filter with the watermark filter
  String watermarkFilter;
  if (isLandscape) {
    // For landscape: watermark at the boundary between videos (around 405px from top)
    watermarkFilter =
        '[stacked]drawbox=x=0:y=405-18:w=iw:h=36:color=white@1:t=fill, '
        'drawtext=text=\'$text\':fontcolor=0x011275:fontsize=12:x=(w-text_w)/2:y=405-18+(36-text_h)/2[final]';
  } else {
    // For portrait: watermark in the middle between videos (around 640px from top)
    watermarkFilter =
        '[stacked]drawbox=x=0:y=640-18:w=iw:h=36:color=white@1:t=fill, '
        'drawtext=text=\'$text\':fontcolor=0x011275:fontsize=12:x=(w-text_w)/2:y=640-18+(36-text_h)/2[final]';
  }

  final command =
      '-i "$videoPath" -i "$selfiePath" '
      '-filter_complex "$stackFilter; $watermarkFilter; [0:a]adelay=${delay * 1000}|${delay * 1000}[delayed_audio]" '
      '-map "[final]" -map "[delayed_audio]" -map 1:a? '
      '-c:v libx264 -preset veryfast -crf 23 '
      '-c:a aac -b:a 128k -ac 2 '
      '"$outputPath"';

  var result = await FFmpegKit.execute(command);

  return result;
}
