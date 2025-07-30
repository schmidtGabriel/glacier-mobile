import 'package:flutter/material.dart';
import 'package:glacier/gate/AuthGate.dart';
import 'package:glacier/pages/send-reaction/GalleryScreen.dart';

class SendReactionStack extends StatelessWidget {
  const SendReactionStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/send-reaction',
      onGenerateRoute: (RouteSettings settings) {
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
