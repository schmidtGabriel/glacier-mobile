import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:intl/intl.dart';

Future<FFmpegSession> addWatermarkWithDate({
  required String videoPath,
  required String outputPath,
}) async {
  final date = DateFormat('LLL d at h:mm a').format(DateTime.now());
  final text = 'Glacier - Verified reaction | $date';

  final command =
      '-i "$videoPath" -vf "drawtext=text=\'$text\':fontcolor=white:fontsize=16:x=(w-text_w)/2:y=(h-text_h)/1.7:box=1:boxcolor=0xADD8E6@0.9:boxborderw=18" -codec:a copy "$outputPath"';

  var result = await FFmpegKit.execute(command);

  return result;
}
