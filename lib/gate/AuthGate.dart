import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:glacier/pages/SigninPage.dart';
import 'package:glacier/services/user/getMe.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return FutureBuilder<bool>(
            future: _ensureUserDataExists(),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.done) {
                if (futureSnapshot.hasError) {
                  return Scaffold(
                    body: Center(child: Text('Error: ${futureSnapshot.error}')),
                  );
                }
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  return const SigninPage();
                }
                return child;
              }
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            },
          );
        } else {
          return const SigninPage();
        }
      },
    );
  }

  Future<bool> _ensureUserDataExists() async {
    final isAuth = FirebaseAuth.instance.currentUser != null;
    if (isAuth) {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      // Only fetch user data if it doesn't exist in SharedPreferences
      if (userString == null || userString.isEmpty) {
        await getMe();
      }
      FlutterNativeSplash.remove();
      return true; // User data now exists
    } else {
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('user'); // Clear user data if not authenticated
      });
    }
    FlutterNativeSplash.remove();
    return false;
  }
}
