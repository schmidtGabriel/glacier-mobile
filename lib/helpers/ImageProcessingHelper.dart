import 'dart:io';

import 'package:flutter/material.dart';

/// Utility class for handling image processing operations
class ImageProcessingHelper {
  /// Opens the image cropping screen and returns the path to the cropped image
  ///
  /// Returns null if the user cancels the cropping operation
  static Future<Object?> cropImage(
    BuildContext context,
    String imagePath,
  ) async {
    try {
      // Validate input parameters
      if (imagePath.isEmpty) {
        print('Error: Empty image path provided to cropImage');
        return null;
      }

      // Check if the file exists before proceeding
      final file = File(imagePath);
      if (!await file.exists()) {
        print('Error: Image file does not exist at path: $imagePath');
        return null;
      }

      final croppedImagePath = await Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed('/crop-image', arguments: {'imagePath': imagePath});

      return croppedImagePath;
    } catch (e) {
      print('Error during image cropping navigation: $e');
      return null;
    }
  }

  /// Validates if the file path is valid and the file exists
  static Future<bool> isValidImageFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      return false;
    }

    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      print('Error validating image file $filePath: $e');
      return false;
    }
  }

  /// Safely deletes a file if it exists
  static Future<void> safeDeleteFile(String? filePath) async {
    if (filePath != null && filePath.isNotEmpty) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting file $filePath: $e');
      }
    }
  }
}
