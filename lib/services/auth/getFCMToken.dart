import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:glacier/services/user/updateUserData.dart';

FirebaseMessaging messaging = FirebaseMessaging.instance;

void initFCM() async {
  print('Initializing Firebase Cloud Messaging...');
  // Request permission
  var settings = await FirebaseMessaging.instance.getNotificationSettings();
  if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
    settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Handle foreground messages
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? token = await messaging.getToken();
    String? apnsToken = await messaging.getAPNSToken();

    // print('FCM Token: $token');
    // print('APNS Token: $apnsToken');
    updateUserData({'fcm_token': token, 'apns_token': apnsToken});
    // Send to your backend server if needed
  }
}
