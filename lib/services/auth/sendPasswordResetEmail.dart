import 'package:firebase_auth/firebase_auth.dart';

Future<void> sendPasswordResetEmail(email) async {
  final FirebaseAuth auth = FirebaseAuth.instance;

  auth
      .sendPasswordResetEmail(email: email)
      .then((value) async {
        print('Password reset email sent to: $email');

        return true;
      })
      .catchError((error) {
        return false; // Rethrow the error to handle it in the UI
      });
}
