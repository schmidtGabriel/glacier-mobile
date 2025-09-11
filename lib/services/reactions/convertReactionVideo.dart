import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Convert video using Firebase Functions and FFmpeg
Future<Map<String, dynamic>?> convertReactionVideo(
  uuid,
  videoPath,
  videoOutputPath,
  void Function(dynamic progress, dynamic total)? onProgress,
  Map<String, dynamic>? options,
) async {
  final FirebaseAuth auth = FirebaseAuth.instance;

  print('Video path: $videoPath');

  try {
    // Validate input paths
    if (videoPath.isEmpty) {
      throw Exception('Invalid video or reaction path');
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

    // Report initial progress
    onProgress?.call(60, 100);

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable(
        'convertVideo',
        options: HttpsCallableOptions(
          timeout: const Duration(
            minutes: 10,
          ), // Increase timeout to 10 minutes
        ),
      );

      // Simulate progress during the call
      Future.delayed(
        Duration(milliseconds: 500),
        () => onProgress?.call(85, 100),
      );
      Future.delayed(Duration(seconds: 1), () => onProgress?.call(90, 100));

      final result = await callable.call({
        'videoPath': videoPath,
        'outputPath': videoOutputPath,
        'uuid': uuid,
        'options': {
          'resolution': options?['resolution'],
          'format': 'mp4',
          'fps': 30,
        },
      });

      // Report completion
      onProgress?.call(100, 100);

      return result.data;
    } on FirebaseFunctionsException catch (error) {
      print("FirebaseFunctionsException:");
      print("  Code: ${error.code}");
      print("  Message: ${error.message}");
      print("  Details: ${error.details}");

      // Handle specific error codes
      switch (error.code) {
        case 'internal':
          print("Internal server error - check Cloud Function logs");
          break;
        case 'unauthenticated':
          print("Authentication required");
          break;
        case 'permission-denied':
          print("Permission denied");
          break;
        case 'invalid-argument':
          print("Invalid arguments provided");
          break;
        case 'deadline-exceeded':
          print(
            "Function timeout - but video processing may still be running in background",
          );
          // You might want to return a special status here instead of null
          // to indicate the operation might still succeed
          break;
        default:
          print("Unknown error code: ${error.code}");
      }
      return null;
    }
  } catch (e) {
    print('Error sending reaction video: $e');
    return null;
  }
}
