import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

signup(data) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  var res = await auth.createUserWithEmailAndPassword(
    email: data.email,
    password: data.password,
  );

  if (res.user == null) {
    print('Signup failed: ${res.toString()}');
    return null;
  }

  final docRef = db.collection('users');

  await docRef
      .doc(res.user!.uid)
      .set({
        'name': data.name,
        'phone': data.phone,
        'email': data.email,
        'created_at': FieldValue.serverTimestamp(),
        'status': 0,
        'role': 10,
        'uuid': res.user!.uid,
      })
      .catchError((error) {
        print('Error creating user document: $error');
      });

  return res;
}
