import 'package:flutter/material.dart';
import 'package:glacier/gate/AuthGate.dart';
import 'package:glacier/pages/home/HomePage.dart';
import 'package:glacier/pages/home/ProfileEditPage.dart';
import 'package:glacier/pages/home/ProfilePage.dart';
import 'package:glacier/pages/home/ReactionDetailPage.dart';

class HomeStack extends StatelessWidget {
  const HomeStack({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Home Stack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/home',
      onGenerateRoute: (RouteSettings settings) {
        final args = settings.arguments;

        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(
              builder: (_) => AuthGate(child: HomePage()),
            );

          case '/profile':
            return MaterialPageRoute(
              builder: (_) => AuthGate(child: ProfilePage()),
            );

          case '/profile-edit':
            return MaterialPageRoute(
              builder: (_) => AuthGate(child: ProfileEditPage()),
            );
          case '/reaction-detail':
            if (args is Map<String, dynamic> && args.containsKey('uuid')) {
              return MaterialPageRoute(
                builder:
                    (_) =>
                        AuthGate(child: ReactionDetailPage(uuid: args['uuid'])),
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
