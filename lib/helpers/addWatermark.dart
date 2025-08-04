import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:intl/intl.dart';

Future<FFmpegSession> addWatermarkWithDate({
  required String videoPath,
  required String outputPath,
}) async {
  final text = getFormattedText();

  final command =
      '-i "$videoPath" -vf "drawbox=x=0:y=ih/1.7:w=iw:h=36:color=white@1:t=fill, drawtext=text=\'$text\':fontcolor=0x011275:fontsize=12:x=(w-text_w)/2:y=(h-text_h)/1.7+19" -codec:a copy "$outputPath"';
  // '-i "$videoPath" -vf "drawbox=x=0:y=ih/2-18:w=iw:h=36:color=white@1:t=fill, drawtext=text=\'$text\':fontcolor=0x011275:fontsize=12:x=(w-text_w)/2:y=ih/2-text_h/2" -codec:a copy "$outputPath"';

  // '-i "$videoPath" -vf "drawbox=y=(h-text_h)/1.7:x=0:w=iw:h=36:color=white@1:t=fill, drawtext=text=\'$text\':fontcolor=0x011275:fontsize=12:x=(w-text_w)/2:y=(h-text_h)/1.7" -codec:a copy "$outputPath"';

  // '-i "$videoPath" -vf "drawtext=text=\'$text\':fontcolor=white:fontsize=16:x=(w-text_w)/2:y=(h-text_h)/1.7:box=1:boxcolor=0xADD8E6@0.9:boxborderw=18" -codec:a copy "$outputPath"';

  var result = await FFmpegKit.execute(command);

  return result;
}

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
