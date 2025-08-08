import 'package:camera/camera.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class PermissionsService {
  static PermissionsService? _instance;
  static final bool _isTestingPermission = false; // Add this flag

  static PermissionsService get instance {
    _instance ??= PermissionsService._internal();
    return _instance!;
  }

  late CameraController _controller;

  PermissionsService._internal();

  /// Check if all critical permissions are granted
  Future<bool> areAllPermissionsGranted() async {
    final notifications = await isNotificationsGranted();
    final gallery = await isGalleryAccessGranted();
    final camera = await isCameraAccessGranted();

    return notifications && gallery && camera;
  }

  /// Get permissions status summary
  Future<PermissionsStatus> getPermissionsStatus() async {
    final notifications = await isNotificationsGranted();
    final gallery = await isGalleryAccessGranted();
    final camera = await isCameraAccessGranted();

    return PermissionsStatus(
      notifications: notifications,
      gallery: gallery,
      camera: camera,
    );
  }

  /// Check if camera permission is granted
  Future<bool> isCameraAccessGranted() async {
    try {
      final status = await Permission.camera.status;
      print('Camera permission status: $status');
      return status.isGranted;
    } catch (e) {
      print('Error checking camera permission: $e');
      return false;
    }
  }

  /// Check if gallery access permission is granted
  Future<bool> isGalleryAccessGranted() async {
    try {
      final permission = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.video,
            mediaLocation: false,
          ),
        ),
      );
      return permission == PermissionState.authorized ||
          permission == PermissionState.limited;
    } catch (e) {
      print('Error checking gallery permission: $e');
      return false;
    }
  }

  /// Check if notifications permission is granted
  Future<bool> isNotificationsGranted() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      print('Notification settings: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Error checking notifications permission: $e');
      return false;
    }
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      final avaiables = await availableCameras();
      _controller = CameraController(avaiables[0], ResolutionPreset.high);
      _controller.initialize();

      final permission = await Permission.camera.request();

      print('Requested camera permission: $permission');
      return permission.isGranted;
    } catch (e) {
      print('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Request gallery access permission
  Future<bool> requestGalleryPermission() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      print('Requested gallery permission: $permission');
      return permission == PermissionState.authorized ||
          permission == PermissionState.limited;
    } catch (e) {
      print('Error requesting gallery permission: $e');
      return false;
    }
  }

  /// Request notifications permission
  Future<bool> requestNotificationsPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      print('Requested notification settings: $settings');
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Error requesting notifications permission: $e');
      return false;
    }
  }
}

class PermissionsStatus {
  final bool notifications;
  final bool gallery;
  final bool camera;

  PermissionsStatus({
    required this.notifications,
    required this.gallery,
    required this.camera,
  });

  bool get allGranted => notifications && gallery && camera;

  List<String> get missingPermissions {
    List<String> missing = [];
    if (!notifications) missing.add('Notifications');
    if (!gallery) missing.add('Gallery Access');
    if (!camera) missing.add('Camera Access');
    return missing;
  }

  @override
  String toString() {
    return 'PermissionsStatus(notifications: $notifications, gallery: $gallery, camera: $camera)';
  }
}
