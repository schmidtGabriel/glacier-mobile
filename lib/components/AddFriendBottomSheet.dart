import 'package:flutter/material.dart';

typedef OnAddFriend = void Function(String name, String emailOrPhone);

class AddFriendBottomSheet extends StatelessWidget {
  final String initialName;
  final OnAddFriend onSubmit;

  const AddFriendBottomSheet({
    super.key,
    required this.initialName,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: initialName);
    final emailController = TextEditingController();

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
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final emailOrPhone = emailController.text.trim();

                    if (name.isNotEmpty && emailOrPhone.isNotEmpty) {
                      onSubmit(name, emailOrPhone);
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in both fields'),
                        ),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    required String initialName,
    required OnAddFriend onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return AddFriendBottomSheet(
          initialName: initialName,
          onSubmit: onSubmit,
        );
      },
    );
  }
}
