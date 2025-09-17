import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:glacier/components/Button.dart';
import 'package:glacier/components/UserAvatar.dart';
import 'package:glacier/helpers/ImageProcessingHelper.dart';
import 'package:glacier/helpers/ToastHelper.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:glacier/services/user/getMe.dart';
import 'package:glacier/services/user/updateUserData.dart';
import 'package:glacier/themes/app_colors.dart';
import 'package:glacier/themes/theme_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  UserResource? user;
  bool isLoading = true;
  bool isSaving = false;
  final uploadService = FirebaseStorageService();
  double _uploadProgress = 0.0;
  String profilePictureUrl = '';

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isLoading)
            TextButton(
              onPressed: isSaving ? null : _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: isSaving ? Colors.grey : Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 20),

                      // Profile Picture Section
                      Center(
                        child: Stack(
                          children: [
                            UserAvatar(
                              userName: user?.name,
                              pictureUrl: profilePictureUrl,
                              size: 100,
                            ),
                            if (_uploadProgress > 0)
                              Positioned.fill(
                                child: CircularProgressIndicator(
                                  value: _uploadProgress,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue,
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _changeProfilePicture,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // User Information Form
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        decoration: ThemeContainers.card(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name Field
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Enter your name',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                                fillColor:
                                    context.isDarkMode
                                        ? AppColors.darkSurface
                                        : AppColors.lightSurface,
                              ),

                              onTapOutside: (event) {
                                FocusScope.of(context).unfocus();
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Name is required';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 24),

                            SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Enter your email',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                                fillColor:
                                    context.isDarkMode
                                        ? AppColors.darkSurface
                                        : AppColors.lightSurface,
                              ),

                              keyboardType: TextInputType.emailAddress,
                              onTapOutside: (event) {
                                FocusScope.of(context).unfocus();
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!RegExp(
                                  r'^[\w\-\.+]+@([\w\-]+\.)+[\w\-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 24),

                            TextField(
                              controller: TextEditingController(
                                text: user?.createdAt ?? '',
                              ),
                              decoration: InputDecoration(
                                labelText: 'Member since',
                                prefixIcon: Icon(
                                  Icons.calendar_today_outlined,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                                fillColor:
                                    context.isDarkMode
                                        ? AppColors.darkSurface
                                        : AppColors.lightSurface,
                              ),

                              readOnly: true,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // Save Button
                      Button(
                        label: 'Save Changes',
                        isLoading: isSaving || _uploadProgress > 0,
                        onPressed: _saveProfile,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString != null && userString.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userString);
        setState(() {
          user = UserResource.fromJson(userMap);
          _nameController.text = user?.name ?? '';
          _emailController.text = user?.email ?? '';
          profilePictureUrl = user?.profilePic ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue, size: 30),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Picture',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  _buildImageOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;
      if (!mounted) return;

      final imagePath = await Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed('/camera', arguments: {'camera': firstCamera});

      if (imagePath is String && imagePath.isNotEmpty) {
        if (!mounted) return;
        // Navigate to crop page
        final croppedImagePath = await ImageProcessingHelper.cropImage(
          context,
          imagePath,
        );

        if (croppedImagePath is String && croppedImagePath.isNotEmpty) {
          await _uploadProfilePicture(croppedImagePath);

          await ImageProcessingHelper.safeDeleteFile(imagePath);
          await ImageProcessingHelper.safeDeleteFile(croppedImagePath);
        } else {
          print('Image cropping was cancelled or failed');
          await ImageProcessingHelper.safeDeleteFile(imagePath);
        }
      }
    } catch (e) {
      print('Camera error: $e');
      ToastHelper.showError(
        context,
        description: 'Error accessing camera. Please try again.',
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null && result.files.single.path != null) {
        final originalFilePath = result.files.single.path!;
        if (!mounted) return;
        // Navigate to crop page
        final croppedImagePath = await ImageProcessingHelper.cropImage(
          context,
          originalFilePath,
        );

        if (croppedImagePath is String && croppedImagePath.isNotEmpty) {
          await _uploadProfilePicture(croppedImagePath);

          await ImageProcessingHelper.safeDeleteFile(croppedImagePath);
        }
      }
    } catch (e) {
      print('Gallery error: $e');
      ToastHelper.showSuccess(
        context,
        description: 'Error accessing gallery. Please try again.',
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      final updatedUserData = await updateUserData(updateData);

      if (updatedUserData != null) {
        if (mounted) {
          ToastHelper.showSuccess(
            context,
            description: 'Profile updated successfully!',
          );
          // Navigate back
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ToastHelper.showError(
            context,
            description: 'Failed to update profile',
          );
        }
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ToastHelper.showError(context, description: 'Error updating profile');
      }
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> _uploadProfilePicture(String imagePath) async {
    try {
      await uploadService
          .uploadProfilePic(
            imagePath,
            onProgress: (sent, total) {
              setState(() {
                _uploadProgress = sent / total;
              });
            },
          )
          .then((value) async {
            ToastHelper.showSuccess(
              context,
              description: 'Profile picture updated successfully!',
            );
            setState(() {
              _uploadProgress = 0.0;
              profilePictureUrl = value ?? '';
            });

            await getMe();
          });
    } catch (e) {
      print('Upload error: $e');
      ToastHelper.showError(
        context,
        description: 'Failed to upload profile picture. Please try again.',
      );
    }
  }
}
