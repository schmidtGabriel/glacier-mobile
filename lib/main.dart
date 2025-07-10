import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glacier/components/BottomMenuLayout.dart';
import 'package:glacier/firebase_options.dart';
import 'package:glacier/gate/AuthGate.dart';
import 'package:glacier/pages/SigninPage.dart';
import 'package:glacier/pages/SignupPage.dart';
import 'package:glacier/pages/TakePictureScreen.dart';
import 'package:glacier/pages/home/RecordPage.dart';
import 'package:glacier/pages/home/RecordedVideoPage.dart';
import 'package:glacier/services/auth/logReaction.dart';
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
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(
      '🔔 Received a message in foreground: ${message.notification?.title}',
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('🔔 Notification clicked: ${message.notification?.title}');

    print('🔔 Notification data: ${message.data}');

    print('🔔 Notification reaction: ${message.data['reaction']}');
    logReaction(message.data['reaction'], message.data);
    navigatorKey.currentState?.pushNamed(
      '/reaction',
      arguments: {'uuid': message.data['reaction']},
    );
    print('🟢 Notification clicked and opened the app');
  });

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
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

          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(builder: (_) => SigninPage());
            case '/signup':
              return MaterialPageRoute(builder: (_) => SignupPage());

            case '/':
              if (args is Map<String, dynamic> && args.containsKey('index')) {
                return MaterialPageRoute(
                  builder:
                      (_) => AuthGate(
                        child: BottomMenuLayout(index: args['index']),
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
