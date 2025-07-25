import 'package:flutter/material.dart';
import 'package:glacier/gate/AuthGate.dart';
import 'package:glacier/pages/send-reaction/GalleryScreen.dart';

class SendReactionStack extends StatelessWidget {
  const SendReactionStack({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Send Reaction',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/send-reaction',
      onGenerateRoute: (RouteSettings settings) {
        final args = settings.arguments;

        switch (settings.name) {
          case '/send-reaction':
            return MaterialPageRoute(
              builder: (_) => AuthGate(child: GalleryScreen()),
            );

          default:
            return _errorRoute();
        }
      },
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
