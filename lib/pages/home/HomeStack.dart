import 'package:flutter/material.dart';
import 'package:glacier/pages/home/HomePage.dart';
import 'package:glacier/pages/home/ProfileEditPage.dart';
import 'package:glacier/pages/home/ProfilePage.dart';
import 'package:glacier/pages/home/ReactionDetailPage.dart';
import 'package:glacier/resources/ReactionResource.dart';

class HomeStack extends StatelessWidget {
  const HomeStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/home',
      onGenerateRoute: (RouteSettings settings) {
        final args = settings.arguments;

        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (_) => HomePage());

          case '/profile':
            return MaterialPageRoute(builder: (_) => ProfilePage());

          case '/profile-edit':
            return MaterialPageRoute(builder: (_) => ProfileEditPage());
          case '/reaction-detail':
            if (args is ReactionResource && args.uuid.isNotEmpty) {
              return MaterialPageRoute(
                builder: (_) => ReactionDetailPage(uuid: args.uuid),
              );
            }
            return _errorRoute();

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
