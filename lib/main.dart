import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:glacier/components/BottomMenuLayout.dart';
import 'package:glacier/firebase_options.dart';
import 'package:glacier/gate/AuthGate.dart';
import 'package:glacier/pages/PermissionsPage.dart';
import 'package:glacier/pages/PreviewVideoPage.dart';
import 'package:glacier/pages/SigninPage.dart';
import 'package:glacier/pages/SignupPage.dart';
import 'package:glacier/pages/TakePictureScreen.dart';
import 'package:glacier/pages/home/RecordPage.dart';
import 'package:glacier/pages/home/RecordedVideoPage.dart';
import 'package:glacier/pages/send-reaction/GalleryScreen.dart';
import 'package:glacier/providers/theme_provider.dart';
import 'package:glacier/services/auth/logReaction.dart';
import 'package:glacier/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  final themeProvider = ThemeProvider();
  await themeProvider.loadFromPrefs();

  runApp(
    ChangeNotifierProvider(create: (_) => themeProvider, child: const MyApp()),
  );
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
    return ToastificationWrapper(
      child: Consumer<ThemeProvider>(
        builder:
            (context, themeProvider, child) => MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              title: 'Glacier',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              builder: (context, child) {
                // Determine if dark mode is active based on themeProvider and system brightness
                final isDark = _getIsDarkMode(themeProvider, context);
                SystemChrome.setSystemUIOverlayStyle(
                  SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness:
                        isDark ? Brightness.light : Brightness.dark,
                    statusBarBrightness:
                        isDark ? Brightness.dark : Brightness.light,
                  ),
                );

                return child!;
              },
              initialRoute: '/',
              onGenerateRoute: (settings) => generateRoutes(settings),
            ),
      ),
    );
  }

  generateRoutes(RouteSettings settings) {
    final args = settings.arguments;

    // Handle deep links - extract path and query parameters from full URL
    String routeName = settings.name ?? '/';
    Map<String, String> queryParams = {};
    // print('🔗 Original Route: $routeName');

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
            builder: (_) => AuthGate(child: RecordPage(uuid: args['uuid'])),
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
                (_) =>
                    AuthGate(child: TakePictureScreen(camera: args['camera'])),
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

      case '/permissions':
        return MaterialPageRoute(
          builder: (_) => AuthGate(child: PermissionsPage()),
        );

      default:
        return _errorRoute();
    }
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

  // Helper method to determine if dark mode is active
  bool _getIsDarkMode(ThemeProvider themeProvider, BuildContext context) {
    switch (themeProvider.themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }
}
