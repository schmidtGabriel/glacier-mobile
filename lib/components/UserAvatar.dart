import 'package:flutter/material.dart';
import 'package:glacier/themes/app_colors.dart';
import 'package:glacier/themes/theme_extensions.dart';

class UserAvatar extends StatefulWidget {
  final String? userName;
  final double size;
  final String? pictureUrl;

  const UserAvatar({
    super.key,
    this.userName,
    this.size = 48.0,
    this.pictureUrl,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.size / 2,
      backgroundColor:
          context.isDarkMode
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurfaceVariant,
      backgroundImage:
          widget.pictureUrl!.isNotEmpty
              ? NetworkImage(widget.pictureUrl!)
              : null,
      child:
          widget.pictureUrl!.isNotEmpty
              ? null
              : widget.pictureUrl!.isEmpty && widget.userName!.isNotEmpty
              ? Text(
                widget.userName![0].toUpperCase(),
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
}
