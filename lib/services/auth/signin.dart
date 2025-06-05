import 'package:firebase_auth/firebase_auth.dart';

Future signin(email, password) async {
  final FirebaseAuth auth = FirebaseAuth.instance;

  auth
      .signInWithEmailAndPassword(email: email, password: password)
      .then((value) async {
        return auth.currentUser;
      })
      .catchError((error) {
        print('Error signing in: $error');
        throw error; // Rethrow the error to handle it in the UI
      });
}
