import 'package:flutter/material.dart';
import 'package:glacier/gate/AuthGate.dart';
import 'package:glacier/pages/PageNotFound.dart';
import 'package:glacier/pages/friends/FriendsPage.dart';

class FriendsStack extends StatelessWidget {
  final int? segment;

  const FriendsStack({super.key, this.segment});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/friends',
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/friends':
            return MaterialPageRoute(
              builder: (_) => AuthGate(child: FriendsPage(segment: segment)),
            );

          default:
            return pageNotFound();
        }
      },
    );
  }
}
