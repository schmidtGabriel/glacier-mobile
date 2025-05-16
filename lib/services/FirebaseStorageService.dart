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
  Future<String?> uploadVideo(String videoPath) async {
    try {
      final fileName = basename(videoPath);
      final storageRef = _storage.ref().child('records/$fileName');

      UploadTask uploadTask = storageRef.putFile(File(videoPath));
      print(File(videoPath));
      TaskSnapshot snapshot = await uploadTask;

      // Get the video URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }
}
