import 'package:flutter/material.dart';
import 'package:glacier/gate/AuthGate.dart';
import 'package:glacier/pages/friends/FriendsPage.dart';

class FriendsStack extends StatelessWidget {
  final int? segment;

  const FriendsStack({super.key, this.segment});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Friends Stack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/friends',
      onGenerateRoute: (RouteSettings settings) {
        final args = settings.arguments;

        switch (settings.name) {
          case '/friends':
            return MaterialPageRoute(
              builder: (_) => AuthGate(child: FriendsPage(segment: segment)),
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
