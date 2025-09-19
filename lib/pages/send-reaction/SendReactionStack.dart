import 'package:flutter/material.dart';
import 'package:glacier/gate/AuthGate.dart';
import 'package:glacier/pages/PageNotFound.dart';
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
            return pageNotFound();
        }
      },
    );
  }
}
