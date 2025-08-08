import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glacier/services/FirebaseStorageService.dart';

Future<Map<String, dynamic>?> completeReaction(
  reaction,
  void Function(dynamic progress, dynamic total)? onProgress,
) async {
  var service = FirebaseStorageService();
  final FirebaseAuth auth = FirebaseAuth.instance;

  var reactionPath = reaction?.reactionPath ?? '';
  var videoPath = reaction?.videoPath ?? '';
  var delayTime = reaction?.delayTime ?? 0;

  print('Selfie path: $reactionPath');
  print('Video 1 URL: $videoPath');
  try {
    // Validate input paths
    if (reactionPath.isEmpty || videoPath.isEmpty) {
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

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('runCompleteRecord');
      final result = await callable.call({
        'videoPath': videoPath,
        'reactionPath': reactionPath,
        'uuid': reaction?.uuid ?? '',
        'delayTime': delayTime,
      });
      return result.data;
    } on FirebaseFunctionsException catch (error) {
      print(error.message);
    }
  } catch (e) {
    print('Error sending reaction video: $e');
    return null;
  }
  return null;
}
