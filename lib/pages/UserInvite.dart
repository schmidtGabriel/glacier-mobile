import 'package:flutter/material.dart';
import 'package:glacier/components/decorations/inputDecoration.dart';

class UserInvite extends StatefulWidget {
  const UserInvite({super.key});

  @override
  _UserInviteState createState() => _UserInviteState();
}

class _UserInviteState extends State<UserInvite> {
  bool friendsLoaded = false;
  bool isLoading = false;
  final TextEditingController _inviteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('Invite Friends'),
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email or SMS', style: Theme.of(context).textTheme.labelLarge),
            SizedBox(height: 8),
            TextField(
              controller: _inviteController,
              decoration: inputDecoration("Enter email or phone number"),
              onTapOutside: (event) {
                FocusScope.of(context).unfocus();
              },
            ),
            SizedBox(height: 16),
            Text('You’re inviting someone who’s not using the app yet.'),
            SizedBox(height: 8),
            Text(
              'Once you confirm, we’ll send them an invitation with instructions to join Glacier and get started.',
            ),

            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: () {
                  if (_inviteController.text.isNotEmpty) {
                    // Handle the invite logic here
                    print('Inviting: ${_inviteController.text}');

                    Navigator.of(context).pop(_inviteController.text);
                    // You can add your invite logic here, like sending an email or SMS
                  }
                },
                child: Text(
                  'Send Invite',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }
}
