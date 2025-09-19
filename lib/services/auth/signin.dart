import 'package:firebase_auth/firebase_auth.dart';
import 'package:glacier/services/friends/updateInvitedUser.dart';

Future signin(email, password) async {
  final FirebaseAuth auth = FirebaseAuth.instance;

  auth
      .signInWithEmailAndPassword(email: email, password: password)
      .then((value) async {
        print('User signed in: ${value.user?.email}');
        await updateInvitedUser(email, auth.currentUser!.uid);

        return auth.currentUser;
      })
      .catchError((error) {
        print('Error signing in: $error');

        return error; // Rethrow the error to handle it in the UI
      });
}
