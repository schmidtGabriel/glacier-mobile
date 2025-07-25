import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendInviteEmail(String to) async {
  final docRef = FirebaseFirestore.instance.collection('mail').doc();

  try {
    await docRef.set({
      'to': [to],
      'message': {
        'subject': 'Welcome to TryGlacier – Email confirmation',
        'html':
            '<h1>Hi there,</h1>'
            '<p>Welcome to Glacier! We\'re excited to have you on board.</p>'
            '<p>This is just a quick confirmation to make sure your email setup is working properly. If you received this message, everything is up and running!</p>'
            '<p>To be part of this exciting journey, please install our app and make your registration by clicking the link below:</p>'
            '<p><a href="https://tryglacier.com/signup?email=$to">Sign Up</a></p>'
            '<p>Best regards,<br>'
            'The Glacier Team</p>',
      },
    });

    print('Sent invite email to $to');
  } catch (e) {
    print('Error sending email: $e');
    rethrow; // Re-throw the error for further handling if needed
  }
}
