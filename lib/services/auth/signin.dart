import 'package:firebase_auth/firebase_auth.dart';

signin(email, password) async {
  final FirebaseAuth auth = FirebaseAuth.instance;

  return await auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}
