// services/firebase_storage_service.dart

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> getDownloadUrl(String pathInStorage) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(pathInStorage);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Erro ao buscar URL: $e');
      return '';
    }
  }

  /// Uploads a video file to Firebase Storage
  Future<String?> uploadRecord(String videoPath, String selfiePath) async {
    try {
      final videoFile = File(videoPath);
      final selfieFile = File(selfiePath);

      if (!videoFile.existsSync()) {
        print('Video file does not exist at path: $videoPath');
        return null;
      }

      if (!selfieFile.existsSync()) {
        print('Selfie file does not exist at path: $selfiePath');
        return null;
      }

      // Upload screen recording
      final fileName = basename(videoPath);
      final storageRef = _storage.ref().child('records/$fileName');

      UploadTask uploadTask = storageRef.putFile(videoFile);
      TaskSnapshot snapshot = await uploadTask;

      // Upload selfie video
      final storageRefSelfie = _storage.ref().child('records/selfie-$fileName');

      UploadTask uploadTaskSelfie = storageRefSelfie.putFile(selfieFile);
      await uploadTaskSelfie;

      // Get the screen recording download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }

  /// Uploads a video file to Firebase Storage
  Future<String?> uploadVideo(String videoPath) async {
    try {
      final videoFile = File(videoPath);

      if (!videoFile.existsSync()) {
        print('Video file does not exist at path: $videoPath');
        return null;
      }

      // Upload screen recording
      final fileName = basename(videoPath);
      final storageRef = _storage.ref().child(
        'videos/${DateTime.now().millisecondsSinceEpoch}-$fileName',
      );

      UploadTask uploadTask = storageRef.putFile(videoFile);
      TaskSnapshot snapshot = await uploadTask;

      // Get the screen recording download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }
}
