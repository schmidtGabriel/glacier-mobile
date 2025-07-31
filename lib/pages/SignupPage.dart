// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:glacier/services/auth/signup.dart';
import 'package:glacier/services/auth/verifyEmail.dart';
import 'package:glacier/themes/theme_extensions.dart';
import 'package:toastification/toastification.dart';

class SignupPage extends StatefulWidget {
  final String email;

  const SignupPage({super.key, this.email = ''});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  int _step = 0;
  bool _obscurePassword = true;
  final String _errorMessage = '';

  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'password': TextEditingController(),
  };

  final _friendEmailController = TextEditingController();
  final List<String> _invitedFriends = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
            _step == 1
                ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _step = 0;
                    });
                  },
                )
                : null,
        title: Text(_step == 0 ? "Sign Up" : "Invite Friends"),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: OverflowBar(
          alignment:
              _step == 1
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.end,
          children: [
            if (_step == 1)
              TextButton(
                onPressed: () {
                  setState(() {
                    _step = 0;
                  });
                },
                child: Text("Back", style: TextStyle(color: Colors.blue)),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: _step == 0 ? _nextStep : _submit,
              child: Text(_step == 0 ? "Next" : "Submit"),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24.0,
                24.0,
                24.0,
                24.0 + MediaQuery.of(context).viewInsets.bottom,
              ),

              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [if (_step == 0) _buildStep1() else _buildStep2()],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _friendEmailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill email if provided
    if (widget.email.isNotEmpty) {
      _controllers['email']!.text = widget.email;
    }
  }

  void _addFriend() {
    final email = _friendEmailController.text.trim();
    if (email.isNotEmpty && !_invitedFriends.contains(email)) {
      setState(() {
        _invitedFriends.add(email);
        _friendEmailController.clear();
      });
    }
  }

  Widget _buildStep1() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 60.0),
          child: Center(
            child:
                context.isDarkMode
                    ? Image.asset('lib/assets/logo-dark.png')
                    : Image.asset('lib/assets/logo.png'),
          ),
        ),
        Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextFormField(
                controller: _controllers['name'],
                decoration: InputDecoration(
                  labelText: "Name",
                  errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                ),
                validator:
                    (value) =>
                        value != null && value.isNotEmpty
                            ? null
                            : "Name is required",

                onTapOutside: (event) {
                  FocusScope.of(context).unfocus();
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _controllers['email'],
                decoration: InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (value) =>
                        value != null && value.contains("@")
                            ? null
                            : "Enter a valid email",
                onTapOutside: (event) {
                  FocusScope.of(context).unfocus();
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _controllers['phone'],
                decoration: InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
                validator:
                    (value) =>
                        value != null && value.isNotEmpty
                            ? null
                            : "Phone is required",
                onTapOutside: (event) {
                  FocusScope.of(context).unfocus();
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _controllers['password'],
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                onTapOutside: (event) {
                  FocusScope.of(context).unfocus();
                },
                validator:
                    (value) =>
                        value != null && value.length >= 6
                            ? null
                            : 'Password too short',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Invite Your Friends",
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        SizedBox(height: 24),
        TextField(
          controller: _friendEmailController,
          decoration: InputDecoration(
            labelText: "Friend's Email",
            suffixIcon: IconButton(
              icon: Icon(Icons.add),
              onPressed: _addFriend,
            ),
          ),
          onTapOutside: (event) {
            FocusScope.of(context).unfocus();
          },
          onSubmitted: (_) => _addFriend(),
        ),
        SizedBox(height: 24),
        Wrap(
          spacing: 8,
          children:
              _invitedFriends
                  .map(
                    (email) => Chip(
                      label: Text(email),
                      onDeleted: () {
                        setState(() {
                          _invitedFriends.remove(email);
                        });
                      },
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  void _nextStep() {
    if (_formKey.currentState?.validate() != true) return;

    verifyEmailAccount(_controllers['email']!.text).then((isRegistered) {
      if (isRegistered) {
        toastification.show(
          title: Text('Ops.'),
          description: Text("Email already registered."),
          autoCloseDuration: const Duration(seconds: 5),
          type: ToastificationType.warning,
          alignment: Alignment.bottomCenter,
        );
      } else {
        if (_step == 0 && _formKey.currentState!.validate()) {
          setState(() {
            _step = 1;
          });
        }
      }
    });
  }

  Future<void> _submit() async {
    try {
      await signup({
        'name': _controllers['name']!.text,
        'email': _controllers['email']!.text,
        'phone': _controllers['phone']!.text,
        'password': _controllers['password']!.text,
        'invited_friends': _invitedFriends,
        'hasAccount': true,
      });
      toastification.show(
        title: Text('Welcome!'),
        description: Text("Signup successful!"),
        autoCloseDuration: const Duration(seconds: 5),
        type: ToastificationType.success,
        alignment: Alignment.bottomCenter,
      );

      Navigator.pop(context); // Navigate back after successful signup
    } catch (e) {
      print('Signup failed: $e');
      toastification.show(
        title: Text('Error.'),
        description: Text(
          'Signup failed: $e' ?? 'An error occurred during signup.',
        ),
        autoCloseDuration: const Duration(seconds: 5),
        type: ToastificationType.error,
        alignment: Alignment.bottomCenter,
      );

      return;
    }
  }
}
