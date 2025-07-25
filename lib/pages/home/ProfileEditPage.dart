import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:glacier/components/Button.dart';
import 'package:glacier/components/decorations/inputDecoration.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:glacier/services/user/getMe.dart';
import 'package:glacier/services/user/updateUserData.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

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
          style: TextStyle(
            color: Colors.black,
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
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey.shade300,
                              child:
                                  profilePictureUrl.isNotEmpty
                                      ? ClipOval(
                                        child: Image.network(
                                          profilePictureUrl,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                      : user!.profilePic.isNotEmpty
                                      ? ClipOval(
                                        child: Image.network(
                                          user!.profilePic,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                      : Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey[600],
                                      ),
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name Field
                            Text(
                              'Name',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: inputDecoration(
                                'Enter your name',
                                Icon(
                                  Icons.person_outline,
                                  color: Colors.grey[600],
                                ),
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

                            // Email Field
                            Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              decoration: inputDecoration(
                                'Enter your email',
                                Icon(
                                  Icons.email_outlined,
                                  color: Colors.grey[600],
                                ),
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

                            // Member Since (Read-only)
                            Text(
                              'Member Since',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    user?.createdAt ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // Save Button
                      Button(
                        label: 'Save Changes',
                        isLoading: isSaving,
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
                      _pickImageFromGallery(context);
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

      final imagePath = await Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed('/camera', arguments: {'camera': firstCamera});

      if (imagePath is String && imagePath.isNotEmpty) {
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
              toastification.show(
                context: context,
                title: Text('Profile picture updated successfully!'),
                type: ToastificationType.success,
                autoCloseDuration: const Duration(seconds: 5),
                alignment: Alignment.bottomCenter,
              );

              setState(() {
                _uploadProgress = 0.0;
                profilePictureUrl = value ?? '';
              });

              await getMe();
              File(imagePath).delete(); // Clean up temp file
            });
      }
    } catch (e) {
      print('Camera error: $e');
    }
  }

  Future<void> _pickImageFromGallery(context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      await uploadService
          .uploadProfilePic(
            result.files.single.path!,
            onProgress: (sent, total) {
              setState(() {
                _uploadProgress = sent / total;
              });
            },
          )
          .then((value) async {
            final file = result.files.single.path!;

            toastification.show(
              context: context,
              title: Text('Profile picture updated successfully!'),
              type: ToastificationType.success,
              autoCloseDuration: const Duration(seconds: 5),
              alignment: Alignment.bottomCenter,
            );

            setState(() {
              _uploadProgress = 0.0;
              profilePictureUrl = value ?? '';
            });

            await getMe();

            File(file).delete();
          });
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
        toastification.show(
          context: context,
          title: Text('Profile updated successfully!'),
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.bottomCenter,
        );

        // Navigate back
        Navigator.pop(context);
      } else {
        toastification.show(
          context: context,
          title: Text('Failed to update profile'),
          description: Text('Please try again later'),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.bottomCenter,
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      toastification.show(
        context: context,
        title: Text('Error updating profile'),
        description: Text('Please try again later'),
        type: ToastificationType.error,
        autoCloseDuration: const Duration(seconds: 3),
        alignment: Alignment.bottomCenter,
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }
}
