import 'package:glacier/services/FirebaseStorageService.dart';

Future<String> handleReaction(data) async {
  try {
    if (data['reaction_path'] != null || data['reaction_path'].isNotEmpty) {
      final service = FirebaseStorageService();
      String res = await service.getDownloadUrl(data['reaction_path']);
      return res;
    } else {
      return '';
    }
  } catch (e) {
    // print('Error fetching selfie URL: $e');
    return '';
  }
}

Future<String> handleRecord(data) async {
  try {
    if (data['record_path'] != null || data['record_path'].isNotEmpty) {
      final service = FirebaseStorageService();
      String res = await service.getDownloadUrl(data['record_path']);
      if (res.isNotEmpty) {
        return res;
      } else {
        return '';
      }
    } else {
      return '';
    }
  } catch (e) {
    // print('Error fetching video URL: $e');
    return '';
  }
}

Future<String> handleVideo(data) async {
  try {
    if (data['video_path'] != null || data['video_path'].isNotEmpty) {
      final service = FirebaseStorageService();
      if (data['type_video'] == '3') {
        String res = await service.getDownloadUrl(data['video_path']);
        return res;
      } else {
        return data['video'] ?? '';
      }
    } else {
      return '';
    }
  } catch (e) {
    // print('Error fetching video URL: $e');
    return '';
  }
}
