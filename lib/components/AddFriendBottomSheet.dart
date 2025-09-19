import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glacier/components/Button.dart';
import 'package:glacier/helpers/ToastHelper.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/services/user/saveFriend.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef OnAddFriend = void Function(String name, String emailOrPhone);

class AddFriendBottomSheet extends StatefulWidget {
  final String initialName;
  final OnAddFriend onSubmit;

  const AddFriendBottomSheet({
    super.key,
    required this.initialName,
    required this.onSubmit,
  });

  @override
  State<AddFriendBottomSheet> createState() => _AddFriendBottomSheetState();
}

class _AddFriendBottomSheetState extends State<AddFriendBottomSheet> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add New Friend',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email or Phone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Button(
                  isLoading: isLoading,
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final emailOrPhone = emailController.text.trim();

                    if (name.isNotEmpty && emailOrPhone.isNotEmpty) {
                      inviteFriend(name, emailOrPhone);
                    } else {
                      ToastHelper.showError(
                        context,
                        message: 'Please fill in both fields',
                      );
                    }
                  },
                  label: 'Add',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName);
    emailController = TextEditingController();
  }

  Future<void> inviteFriend(String name, String email) async {
    if (email.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> userMap = jsonDecode(prefs.getString('user') ?? '{}');
    var user = UserResource.fromJson(userMap);

    setState(() {
      isLoading = true;
    });

    saveFriend(user.uuid, email)
        .then(
          (value) async => {
            if (mounted)
              {
                setState(() {}),
                if (!value.error)
                  {
                    ToastHelper.showSuccess(
                      context,
                      message: 'Friend Request Sent',
                      description: 'A friend request has been sent to $email.',
                    ),
                    widget.onSubmit(name, email),
                  }
                else
                  {
                    ToastHelper.showError(
                      context,
                      message: 'Friend Request failed',
                      description: value.message,
                    ),
                  },

                setState(() {
                  isLoading = false;
                }),
              },
          },
        )
        .catchError((error) {
          ToastHelper.showError(
            context,
            message: 'Friend Request failed',
            description: error.message.toString(),
          );

          return error;
        });
  }
}
