import 'package:flutter/material.dart';

class UserAvatar extends StatefulWidget {
  final user;

  const UserAvatar({super.key, this.user});

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String picture = '';
  String name = '';

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: picture.isNotEmpty ? NetworkImage(picture) : null,
      child:
          picture.isEmpty && name.isNotEmpty
              ? Text(
                name[0].toUpperCase(),
                style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
              )
              : Icon(Icons.person, color: Colors.grey.shade600, size: 24),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      picture = widget.user['profile_picture'] ?? '';
      name = widget.user['name'] ?? '';
    }
  }
}
