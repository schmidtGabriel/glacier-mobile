import 'package:flutter/material.dart';
import 'package:glacier/services/PermissionsService.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  bool _notificationsGranted = false;
  bool _galleryGranted = false;
  bool _cameraGranted = false;
  bool _screenRecordingGranted = false;
  final bool _isLoading = false;

  final _permissionsService = PermissionsService.instance;

  bool get _allPermissionsGranted {
    return _notificationsGranted &&
        _galleryGranted &&
        _cameraGranted &&
        _screenRecordingGranted;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('App Permissions'),
          backgroundColor: Colors.transparent,
        ),
        body:
            _isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Checking permissions...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.blue.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.security, color: Colors.white, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'Grant Permissions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'To provide you with the best experience, Glacier needs access to certain features on your device.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      // Permission Cards
                      _buildPermissionCard(
                        icon: Icons.notifications,
                        title: 'Notifications',
                        description:
                            'Receive friend requests, reaction updates, and important alerts',
                        isGranted: _notificationsGranted,
                        onTap: _requestNotificationPermission,
                      ),

                      SizedBox(height: 16),

                      _buildPermissionCard(
                        icon: Icons.photo_library,
                        title: 'Gallery Access',
                        description:
                            'Select videos from your device to create and share reactions',
                        isGranted: _galleryGranted,
                        onTap: _requestGalleryPermission,
                      ),

                      SizedBox(height: 16),

                      _buildPermissionCard(
                        icon: Icons.camera_alt,
                        title: 'Camera Access',
                        description:
                            'Record your reactions and take photos within the app',
                        isGranted: _cameraGranted,
                        onTap: _requestCameraPermission,
                      ),

                      SizedBox(height: 16),

                      _buildPermissionCard(
                        icon: Icons.screen_share,
                        title: 'Screen Recording',
                        description:
                            'Record your screen to capture reactions to videos and content',
                        isGranted: _screenRecordingGranted,
                        onTap: _requestScreenRecordingPermission,
                      ),

                      // Card(
                      //   elevation: 2,
                      //   shape: RoundedRectangleBorder(
                      //     borderRadius: BorderRadius.circular(12),
                      //   ),
                      //   child: InkWell(
                      //     onTap: null,
                      //     borderRadius: BorderRadius.circular(12),
                      //     child: Padding(
                      //       padding: EdgeInsets.all(16),
                      //       child: Row(
                      //         children: [
                      //           Container(
                      //             width: 48,
                      //             height: 48,
                      //             decoration: BoxDecoration(
                      //               color: Colors.orange.shade600,
                      //               borderRadius: BorderRadius.circular(12),
                      //             ),
                      //             child: Icon(
                      //               Icons.screen_share,
                      //               color: Colors.white,
                      //               size: 24,
                      //             ),
                      //           ),
                      //           SizedBox(width: 16),
                      //           Expanded(
                      //             child: Column(
                      //               crossAxisAlignment: CrossAxisAlignment.start,
                      //               children: [
                      //                 Text(
                      //                   'Screen Recording',
                      //                   style: TextStyle(
                      //                     fontSize: 16,
                      //                     fontWeight: FontWeight.w600,
                      //                     color: Colors.grey.shade800,
                      //                   ),
                      //                 ),
                      //                 SizedBox(height: 4),
                      //                 Text(
                      //                   'This feature requires your permission, we will request it when you try to use it.',
                      //                   style: TextStyle(
                      //                     fontSize: 14,
                      //                     color: Colors.grey.shade600,
                      //                   ),
                      //                 ),
                      //               ],
                      //             ),
                      //           ),
                      //           SizedBox(width: 16),
                      //           Container(
                      //             width: 24,
                      //             height: 24,
                      //             decoration: BoxDecoration(
                      //               color: Colors.orange.shade600,
                      //               shape: BoxShape.circle,
                      //             ),
                      //             child: Icon(
                      //               Icons.warning,
                      //               color: Colors.white,
                      //               size: 16,
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      SizedBox(height: 32),

                      // Action Buttons
                      if (!_allPermissionsGranted) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _requestAllPermissions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'Grant All Permissions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_allPermissionsGranted) {
                              Navigator.of(context).pop(true);
                            } else {
                              Navigator.of(context).pop(false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _allPermissionsGranted
                                    ? Colors.green.shade600
                                    : Colors.grey.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            _allPermissionsGranted
                                ? 'Continue to App'
                                : 'Continue Anyway',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Privacy Note
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.privacy_tip,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your privacy is important to us. These permissions are only used to provide app functionality and your data is never shared without consent.',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // _checkCurrentPermissions();
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isGranted ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      isGranted ? Colors.green.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                      isGranted ? Colors.green.shade600 : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color:
                      isGranted ? Colors.green.shade600 : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGranted ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkCurrentPermissions() async {
    try {
      final status = await _permissionsService.getPermissionsStatus();
      setState(() {
        _notificationsGranted = status.notifications;
        _galleryGranted = status.gallery;
        _cameraGranted = status.camera;
        _screenRecordingGranted = status.screenRecording;
      });
    } catch (e) {
      print('Error checking permissions: $e');
    }
  }

  void _requestAllPermissions() async {
    await _requestNotificationPermission();

    await _requestGalleryPermission();

    await _requestScreenRecordingPermission();

    await _requestCameraPermission();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permission requests completed!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _requestCameraPermission() async {
    try {
      final granted = await _permissionsService.requestCameraPermission();
      setState(() {
        _cameraGranted = granted;
      });

      if (!granted) {
        _showPermissionDeniedDialog(
          'Camera Access',
          'To record reactions, please enable camera access in your device settings.',
        );
      }
    } catch (e) {
      print('Error requesting camera permission: $e');
      setState(() {
        _cameraGranted = false;
      });
    }
  }

  Future<void> _requestGalleryPermission() async {
    try {
      final granted = await _permissionsService.requestGalleryPermission();
      setState(() {
        _galleryGranted = granted;
      });

      if (!granted) {
        _showPermissionDeniedDialog(
          'Gallery Access',
          'To select videos from your gallery, please enable photo access in your device settings.',
        );
      }
    } catch (e) {
      print('Error requesting gallery permission: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final granted =
          await _permissionsService.requestNotificationsPermission();
      print('Notification permission granted: $granted');
      setState(() {
        _notificationsGranted = granted;
      });

      if (!granted) {
        _showPermissionDeniedDialog(
          'Notifications',
          'To receive important updates and friend requests, please enable notifications in your device settings.',
        );
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
    }
  }

  Future<void> _requestScreenRecordingPermission() async {
    try {
      final granted =
          await _permissionsService.requestScreenRecordingPermission();
      setState(() {
        _screenRecordingGranted = granted;
      });

      print('Screen recording permission granted: $granted');

      if (!granted) {
        _showPermissionDeniedDialog(
          'Screen Recording',
          'To record your screen reactions, please enable screen recording access in your device settings.',
        );
      }
    } catch (e) {
      print('Error requesting screen recording permission: $e');
      setState(() {
        _screenRecordingGranted = false;
      });
    }
  }

  void _showPermissionDeniedDialog(String permissionName, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionName Permission'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}
