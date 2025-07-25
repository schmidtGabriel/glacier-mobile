import 'package:flutter/material.dart';

class UserAvatar extends StatefulWidget {
  final user;
  final double size;

  const UserAvatar({super.key, this.user, this.size = 48.0});

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String picture = '';
  String name = '';

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.size / 2,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: picture.isNotEmpty ? NetworkImage(picture) : null,
      child:
          picture.isEmpty && name.isNotEmpty
              ? Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: widget.size * 0.6,
                  color: Colors.grey.shade600,
                ),
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
      picture = widget.user?.profilePic ?? '';
      name = widget.user?.name ?? '';
    }
  }
}
