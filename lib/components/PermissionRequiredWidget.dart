import 'package:flutter/material.dart';
import 'package:glacier/services/PermissionsService.dart';

class PermissionRequiredWidget extends StatefulWidget {
  final List<PermissionType> requiredPermissions;
  final Widget child;
  final Widget? fallback;
  final String? title;
  final String? description;

  const PermissionRequiredWidget({
    super.key,
    required this.requiredPermissions,
    required this.child,
    this.fallback,
    this.title,
    this.description,
  });

  @override
  State<PermissionRequiredWidget> createState() =>
      _PermissionRequiredWidgetState();
}

enum PermissionType { notifications, gallery, camera, screenRecording }

/// Utility class for showing permission-related dialogs and messages
class PermissionUtils {
  static SnackBar permissionDeniedSnackBar(String permissionName) {
    return SnackBar(
      content: Text('$permissionName permission is required for this feature'),
      action: SnackBarAction(
        label: 'Settings',
        onPressed: () {
          // Open app settings - platform specific implementation needed
        },
      ),
      backgroundColor: Colors.orange,
    );
  }

  static void showPermissionRationale(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onSettings,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            if (onSettings != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onSettings();
                },
                child: Text('Settings'),
              ),
          ],
        );
      },
    );
  }
}

class _PermissionRequiredWidgetState extends State<PermissionRequiredWidget> {
  bool _permissionsGranted = false;
  bool _isLoading = true;
  final _permissionsService = PermissionsService.instance;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_permissionsGranted) {
      return widget.child;
    }

    return widget.fallback ?? _buildDefaultFallback();
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Widget _buildDefaultFallback() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            widget.title ?? 'Permissions Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            widget.description ??
                'This feature requires additional permissions to work properly.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.of(
                context,
              ).pushNamed('/permissions');
              if (result == true) {
                _checkPermissions();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    bool allGranted = true;

    for (final permission in widget.requiredPermissions) {
      bool granted = false;
      switch (permission) {
        case PermissionType.notifications:
          granted = await _permissionsService.isNotificationsGranted();
          break;
        case PermissionType.gallery:
          granted = await _permissionsService.isGalleryAccessGranted();
          break;
        case PermissionType.camera:
          granted = await _permissionsService.isCameraAccessGranted();
          break;
        case PermissionType.screenRecording:
          granted =
              true; // Screen recording is typically granted when first used
          break;
      }

      if (!granted) {
        allGranted = false;
        break;
      }
    }

    setState(() {
      _permissionsGranted = allGranted;
      _isLoading = false;
    });
  }
}
