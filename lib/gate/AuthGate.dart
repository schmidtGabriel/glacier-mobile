import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glacier/pages/SigninPage.dart';
import 'package:glacier/services/user/getUserData.dart';

class AuthGate extends StatelessWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance.authStateChanges(), // Listen to auth changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          getUserData();

          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            return const SigninPage();
          }
          return child;
        } else {
          return const SigninPage();
        }
      },
    );
  }
}
