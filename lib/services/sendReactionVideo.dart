import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> sendReactionVideo(
  video1Url,
  void Function(dynamic progress, dynamic total)? onProgress,
) async {
  var service = FirebaseStorageService();
  var prefs = await SharedPreferences.getInstance();
  final FirebaseAuth auth = FirebaseAuth.instance;

  var selfiePath = prefs.getString('selfiePath') ?? '';

  print('Selfie path: $selfiePath');
  print('Video 1 URL: $video1Url');
  try {
    // Validate input paths
    if (selfiePath.isEmpty) {
      throw Exception('Invalid video or selfie path');
    }

    final value = await service.uploadReaction(
      selfiePath,
      onProgress: (sent, total) {
        onProgress?.call(sent, total);
      },
    );
    if (value == null) {
      throw Exception('Failed to upload video or selfie');
    }

    final user = auth.currentUser;
    if (user == null) {
      // User is not signed in
      print("User is not authenticated");
      return null;
    } else {
      // User is authenticated
      print("User is authenticated: ${user.email}");
    }

    await auth.currentUser?.getIdToken(true);

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('runFFmpeg');
      final result = await callable.call({
        'video1Url': video1Url,
        'video2Url': value,
      });
      return result.data['videoUrl'];
    } on FirebaseFunctionsException catch (error) {
      print(error.message);
    }
  } catch (e) {
    print('Error sending reaction video: $e');
    return '';
  }
  return null;
}
