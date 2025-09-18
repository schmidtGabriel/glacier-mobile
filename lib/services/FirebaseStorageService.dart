// services/firebase_storage_service.dart

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:glacier/helpers/editReactionVideo.dart';
import 'package:glacier/resources/ReactionResource.dart';
import 'package:glacier/services/user/updateUserData.dart';
import 'package:native_media_converter/native_media_converter.dart';
// import 'package:native_media_converter/native_media_converter.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> getDownloadUrl(String pathInStorage) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(pathInStorage);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      // print('Erro ao buscar URL: $e');
      return '';
    }
  }

  /// Uploads a video file to Firebase Storage
  Future<String?> uploadProfilePic(
    String photoPath, {
    void Function(dynamic progress, dynamic total)? onProgress,
  }) async {
    try {
      final videoFile = File(photoPath);

      if (!videoFile.existsSync()) {
        print('Video file does not exist at path: $photoPath');
        return null;
      }

      // Upload screen recording
      final fileName = basename(photoPath);
      final storageRef = _storage.ref().child('profile/$fileName');

      UploadTask uploadTask = storageRef.putFile(videoFile);

      // Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final sent = snapshot.bytesTransferred;
        final total = snapshot.totalBytes;
        onProgress!(sent, total);
      });

      TaskSnapshot snapshot = await uploadTask;

      await updateUserData({'profile_picture': 'profile/$fileName'});

      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }

  /// Uploads a video file to Firebase Storage
  Future<Map<String, String>?> uploadRecord(ReactionResource? reaction) async {
    try {
      if (reaction == null) {
        print('Reaction is null.');
        return null;
      }

      var resultReaction = await processVideo(reaction);

      if (resultReaction == null || resultReaction.isEmpty) {
        print('Processed video path is invalid.');
        return null;
      }

      final finalVideoPath = File(resultReaction);
      print('Final video path: $finalVideoPath');
      // Upload screen recording
      final fileName = basename(resultReaction);
      final path = 'finals/$fileName';
      final storageRef = _storage.ref().child(path);

      UploadTask uploadTask = storageRef.putFile(finalVideoPath);
      TaskSnapshot snapshot = await uploadTask;

      finalVideoPath.delete();

      // Get the screen recording download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return {'url': downloadUrl, 'filePath': path};
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }

  Future<Map<String, String>?> uploadVideo(
    String videoPath,
    String videoFolder,
    String videoName, {
    void Function(dynamic progress, dynamic total)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();

      final tempVideoPath =
          '${tempDir.path}/${videoName.endsWith('.mp4') ? videoName : '$videoName.mp4'}';

      // NativeMediaConverter.progressStream().listen((progress) {
      //   print("Progress: ${(progress * 100).toStringAsFixed(1)}%");
      // });

      // const MethodChannel('media_converter_flutter').invokeMethod('transcode', {
      //   'inputPath': videoPath,
      //   'outputPath': tempVideoPath,
      //   'crop': {'x': 100, 'y': 100, 'w': 800, 'h': 600},
      //   'resolution': {'w': 1280, 'h': 720},
      //   'bitrate': 5000000,
      //   'fps': 30,
      //   'codec': 'h264',
      //   'hdr': true,
      // });

      // await convertVideo(
      //   videoPath: videoPath,
      //   outputPath: tempVideoPath,
      //   onProgress: (progress) {
      //     // Convert progress is 0-50% of total progress
      //     final totalProgress = progress * 0.5;
      //     onProgress?.call(totalProgress, 1.0);
      //   },
      // );

      NativeMediaConverter.progressStream().listen((p) {
        onProgress?.call(p * 0.5, 1.0);
      });

      final opts = ConvertOptions(
        inputPath: videoPath,
        outputPath: tempVideoPath,
        width: 1280,
        height: 720,
        resolution: 720,
        fps: 30,
        videoBitrate: 2_000_000, // Reduced bitrate for faster processing
        codec: "h264",
        container: "mp4",
        // crop: { 'x': 500, 'y': 300, 'width': 1280, 'height': 720 },
        hdr: HDROptions(isHdr: false), // Set to false for better compatibility
      );

      final outPath = await NativeMediaConverter.transcode(opts);

      // final videoFile = File(tempVideoPath);
      final videoFile = File(outPath);

      if (!videoFile.existsSync()) {
        print('Video file does not exist at path: $videoPath');
        return null;
      }

      // Upload screen recording
      final fileName =
          videoName.endsWith('.mp4') ? videoName : '$videoName.mp4';
      final filePath = '$videoFolder/$fileName';
      final storageRef = _storage.ref().child(filePath);

      UploadTask uploadTask = storageRef.putFile(videoFile);

      // Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final sent = snapshot.bytesTransferred;
        final total = snapshot.totalBytes;
        // Upload progress is 50-100% of total progress
        final uploadProgress = sent / total;
        final totalProgress = 0.5 + (uploadProgress * 0.5);
        onProgress!(totalProgress, 1.0);
      });

      TaskSnapshot snapshot = await uploadTask;

      videoFile.delete();

      // Get the screen recording download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return {'url': downloadUrl, 'filePath': filePath};
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }
}
