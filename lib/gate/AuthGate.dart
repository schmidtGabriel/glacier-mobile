import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_truereaction/pages/HomePage.dart';
import 'package:test_truereaction/pages/SigninPage.dart';
import 'package:test_truereaction/services/getUserData.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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

          return const HomePage(); // User is logged in
        } else {
          return const SigninPage(); // User is not logged in
        }
      },
    );
  }
}
