// services/firebase_storage_service.dart

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:glacier/services/user/updateUserData.dart';
import 'package:path/path.dart';

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

  Future<String?> uploadReaction(
    String videoPath, {
    void Function(dynamic progress, dynamic total)? onProgress,
  }) async {
    try {
      final videoFile = File(videoPath);

      // Check if the file exists
      if (!videoFile.existsSync()) {
        print('Video file does not exist at path: $videoPath');
        return null;
      }

      // Upload screen recording
      final fileName = basename(videoPath);
      final storageRef = _storage.ref().child('reactions/$fileName');

      UploadTask uploadTask = storageRef.putFile(videoFile);

      // Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final sent = snapshot.bytesTransferred;
        final total = snapshot.totalBytes;
        onProgress!(sent, total);
      });

      TaskSnapshot snapshot = await uploadTask;

      // Get the screen recording download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload failed: $e');
      return null;
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
      final storageRefSelfie = _storage.ref().child('reactions/$fileName');

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

  Future<Map<String, String>?> uploadVideo(
    String videoPath, {
    void Function(dynamic progress, dynamic total)? onProgress,
  }) async {
    try {
      final videoFile = File(videoPath);

      if (!videoFile.existsSync()) {
        print('Video file does not exist at path: $videoPath');
        return null;
      }

      // Upload screen recording
      final fileName = basename(videoPath);
      final filePath = 'videos/$fileName';
      final storageRef = _storage.ref().child(filePath);

      UploadTask uploadTask = storageRef.putFile(videoFile);

      // Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final sent = snapshot.bytesTransferred;
        final total = snapshot.totalBytes;
        onProgress!(sent, total);
      });

      TaskSnapshot snapshot = await uploadTask;

      // Get the screen recording download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return {'url': downloadUrl, 'filePath': filePath};
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }
}
