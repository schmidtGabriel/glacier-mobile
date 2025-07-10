import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glacier/services/handleInvitation.dart';
import 'package:toastification/toastification.dart';

Future signin(email, password) async {
  final FirebaseAuth auth = FirebaseAuth.instance;

  auth
      .signInWithEmailAndPassword(email: email, password: password)
      .then((value) async {
        print('User signed in: ${value.user?.email}');
        await handleInvitations(email, auth.currentUser!.uid);

        return auth.currentUser;
      })
      .catchError((error) {
        print('Error signing in: $error');
        toastification.show(
          title: Text('Sign-in failed.'),
          description: Text(" ${error.toString()}"),
          autoCloseDuration: const Duration(seconds: 5),
          type: ToastificationType.error,
          alignment: Alignment.bottomCenter,
        );
        return error; // Rethrow the error to handle it in the UI
      });
}
