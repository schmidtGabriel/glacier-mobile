import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<Map<String, dynamic>?> convertReactionVideoWithPolling(
  String uuid,
  String videoPath,
  String videoOutputPath,
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
      print("User is not authenticated");
      return null;
    }

    await auth.currentUser?.getIdToken(true);

    // Start the conversion job
    final startCallable = FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('startVideoConversion');

    final startResult = await startCallable.call({
      'videoPath': videoPath,
      'outputPath': videoOutputPath,
      'uuid': uuid,
      'options': options,
    });

    final jobId = startResult.data['jobId'];
    if (jobId == null) {
      throw Exception('Failed to start conversion job');
    }

    // Poll for progress
    final statusCallable = FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('getConversionStatus');

    Timer? pollTimer;
    final completer = Completer<Map<String, dynamic>?>();

    pollTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      try {
        final statusResult = await statusCallable.call({'jobId': jobId});
        final data = statusResult.data;

        if (data['status'] == 'completed') {
          onProgress?.call(100, 100);
          timer.cancel();
          completer.complete(data['result']);
        } else if (data['status'] == 'failed') {
          timer.cancel();
          completer.completeError(
            Exception('Conversion failed: ${data['error']}'),
          );
        } else if (data['status'] == 'processing') {
          final progress = data['progress'] ?? 0;
          onProgress?.call(progress, 100);
        }
      } catch (e) {
        timer.cancel();
        completer.completeError(e);
      }
    });

    // Set a timeout
    Timer(Duration(minutes: 10), () {
      pollTimer?.cancel();
      if (!completer.isCompleted) {
        completer.completeError(Exception('Conversion timeout'));
      }
    });

    return await completer.future;
  } catch (e) {
    print('Error in video conversion: $e');
    return null;
  }
}
