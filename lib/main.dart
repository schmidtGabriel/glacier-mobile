import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:glacier/components/BottomMenuLayout.dart';
import 'package:glacier/firebase_options.dart';
import 'package:glacier/gate/AuthGate.dart';
import 'package:glacier/pages/SigninPage.dart';
import 'package:glacier/pages/SignupPage.dart';
import 'package:glacier/pages/home/RecordPage.dart';
import 'package:glacier/pages/home/RecordedVideoPage.dart';
import 'package:toastification/toastification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // initFCM();

  // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //   print(
  //     '🔔 Received a message in foreground: ${message.notification?.title}',
  //   );
  // });

  // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //   navigatorKey.currentState?.push(
  //     MaterialPageRoute(
  //       builder: (context) => RecordPage(uuid: message.data['reaction']),
  //     ),
  //   );
  //   print('🟢 Notification clicked and opened the app');
  // });

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   print("Handling a background message: ${message.messageId}");
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'Glacier',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
              return MaterialPageRoute(
                builder: (_) => AuthGate(child: BottomMenuLayout()),
              );

            case '/reaction':
              if (args is Map<String, dynamic> && args.containsKey('uuid')) {
                print(args['uuid']);
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
