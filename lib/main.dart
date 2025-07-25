import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glacier/components/BottomMenuLayout.dart';
import 'package:glacier/firebase_options.dart';
import 'package:glacier/gate/AuthGate.dart';
import 'package:glacier/pages/PreviewVideoPage.dart';
import 'package:glacier/pages/SigninPage.dart';
import 'package:glacier/pages/SignupPage.dart';
import 'package:glacier/pages/TakePictureScreen.dart';
import 'package:glacier/pages/home/RecordPage.dart';
import 'package:glacier/pages/home/RecordedVideoPage.dart';
import 'package:glacier/pages/send-reaction/GalleryScreen.dart';
import 'package:glacier/services/auth/logReaction.dart';
import 'package:glacier/services/getFCMToken.dart';
import 'package:toastification/toastification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set default status bar icons color to black
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness:
          Brightness.dark, // Dark icons on light background
      statusBarBrightness: Brightness.light, // For iOS
    ),
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  initFCM();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(
      '🔔 Received a message in foreground: ${message.notification?.title}',
    );
  });

  // Handle notification clicks when app is in background or foreground
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print(
      '🔔 Notification clicked (app in background): ${message.notification?.title}',
    );
    _handleNotificationData(message);
  });

  // Handle notification clicks when app is terminated and opened via notification
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print(
        '🔔 App opened from notification (terminated state): ${message.notification?.title}',
      );
      // Delay handling to ensure the navigator is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationData(message);
      });
    }
  });

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void _handleNotificationData(RemoteMessage message) {
  print('🔔 Handling notification data: ${message.data}');
  print('🔔 Notification title: ${message.notification?.title}');
  print('🔔 Notification body: ${message.notification?.body}');

  logReaction('', message.data);

  // Check if we have a reaction UUID to navigate to
  if (message.data.containsKey('reaction') &&
      message.data['reaction'] != null) {
    print('🔔 Navigating to reaction: ${message.data['reaction']}');
    navigatorKey.currentState?.pushNamed(
      '/reaction',
      arguments: {'uuid': message.data['reaction']},
    );
  }

  // Check if we have a specific page to navigate to
  if (message.data.containsKey('page') && message.data['page'] != null) {
    print('🔔 Navigating to page: ${message.data['page']}');
    switch (message.data['page']) {
      case 'pending-friends':
        navigatorKey.currentState?.pushNamed(
          '/',
          arguments: {'index': 2, 'segment': 1},
        );
        break;

      default:
        print('Unknown page: ${message.data['page']}');
    }
  }

  print('🟢 Notification handled successfully');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'Glacier',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          appBarTheme: const AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: Brightness.dark, // Dark icons
              statusBarBrightness: Brightness.light, // For iOS
            ),
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          final args = settings.arguments;

          // Handle deep links - extract path and query parameters from full URL
          String routeName = settings.name ?? '/';
          Map<String, String> queryParams = {};
          print('🔗 Original Route: $routeName');

          if (routeName.contains('?')) {
            try {
              final uri = Uri.parse(routeName);
              routeName = uri.path.isEmpty ? '/' : uri.path;
              queryParams = Map<String, String>.from(uri.queryParameters);
            } catch (e) {
              print('🔗 Error parsing URL: $e');
              routeName = '/';
            }
          } else {
            queryParams = {};
          }

          switch (routeName) {
            case '/login':
              return MaterialPageRoute(builder: (_) => SigninPage());
            case '/signup':
              return MaterialPageRoute(
                builder: (_) => SignupPage(email: queryParams['email'] ?? ''),
              );

            case '/':
              if (args is Map<String, dynamic> && args.containsKey('index')) {
                return MaterialPageRoute(
                  builder:
                      (_) => AuthGate(
                        child: BottomMenuLayout(
                          index: args['index'],
                          segment: args['segment'],
                        ),
                      ),
                );
              }
              return MaterialPageRoute(
                builder: (_) => AuthGate(child: BottomMenuLayout(index: 0)),
              );

            case '/reaction':
              if (args is Map<String, dynamic> && args.containsKey('uuid')) {
                return MaterialPageRoute(
                  builder:
                      (_) => AuthGate(child: RecordPage(uuid: args['uuid'])),
                );
              }
              return _errorRoute();

            case '/recorded-video':
              if (args is Map<String, dynamic>) {
                return MaterialPageRoute(
                  builder:
                      (_) => AuthGate(
                        child: RecordedVideoPage(
                          videoPath: args['videoPath'],
                          videoName: args['videoName'],
                          uuid: args['uuid'],
                        ),
                      ),
                );
              }
              return _errorRoute();

            case '/camera':
              if (args is Map<String, dynamic> && args.containsKey('camera')) {
                return MaterialPageRoute(
                  builder:
                      (_) => AuthGate(
                        child: TakePictureScreen(camera: args['camera']),
                      ),
                );
              }
              return _errorRoute();

            case '/gallery':
              return MaterialPageRoute(
                builder: (_) => AuthGate(child: GalleryScreen()),
              );

            case '/preview-video':
              if (args is Map<String, dynamic>) {
                return MaterialPageRoute(
                  builder:
                      (_) => AuthGate(
                        child: PreviewVideoPage(
                          localVideo: args['localVideo'],
                          videoPath: args['videoPath'],
                          hasConfirmButton: args['hasConfirmButton'] ?? false,
                        ),
                      ),
                );
              }
              return _errorRoute();

            default:
              return _errorRoute();
          }
        },
      ),
    );
  }

  Route _errorRoute() {
    return MaterialPageRoute(
      builder:
          (_) => Scaffold(
            appBar: AppBar(title: Text("Error")),
            body: Center(child: Text("Page not found or invalid arguments")),
          ),
    );
  }
}
