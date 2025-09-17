import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glacier/helpers/ToastHelper.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageCropPage extends StatefulWidget {
  final String imagePath;

  const ImageCropPage({super.key, required this.imagePath});

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  bool isLoading = false;
  String? croppedImagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Image'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading image editor...'),
                  ],
                ),
              )
              : croppedImagePath != null
              ? _buildPreview()
              : const Center(child: Text('Image cropping cancelled')),
    );
  }

  @override
  void initState() {
    super.initState();
    _cropImage();
  }

  Widget _buildPreview() {
    final imagePath = croppedImagePath;
    if (imagePath == null || imagePath.isEmpty) {
      return const Center(child: Text('No image to preview'));
    }

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Failed to load image'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cropImage,
                    child: const Text('Crop Again'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, croppedImagePath);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Use Image'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cropImage() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Validate the source image path
      if (widget.imagePath.isEmpty) {
        throw Exception('Source image path is empty');
      }

      final sourceFile = File(widget.imagePath);
      if (!await sourceFile.exists()) {
        throw Exception(
          'Source image file does not exist: ${widget.imagePath}',
        );
      }

      print('Starting image crop for: ${widget.imagePath}');

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: widget.imagePath,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 90,
        maxWidth: 1024,
        maxHeight: 1024,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            embedInNavigationController: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 520, height: 520),
            dragMode: WebDragMode.crop,
            initialAspectRatio: 1,
          ),
        ],
      );

      print('Crop result: ${croppedFile?.path ?? "null"}');

      if (croppedFile != null) {
        print('Cropping successful: ${croppedFile.path}');
        setState(() {
          croppedImagePath = croppedFile.path;
          isLoading = false;
        });
      } else {
        // User cancelled cropping
        print('User cancelled image cropping');
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error cropping image: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ToastHelper.showError(context, description: 'Error cropping image: $e');
        Navigator.pop(context);
      }
    }
  }
}
