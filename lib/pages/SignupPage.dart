// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:glacier/components/decorations/inputDecoration.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  int _step = 0;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _friendEmailController = TextEditingController();
  final List<String> _invitedFriends = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
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
      backgroundColor: Colors.grey[200],
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24.0,
              24.0,
              24.0,
              24.0 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Expanded(
              flex: 1,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [if (_step == 0) _buildStep1() else _buildStep2()],
                ),
              ),
            ),
          );
        },
      ),
    );
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
    return Expanded(
      flex: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: inputDecoration("Name"),
                  validator:
                      (value) =>
                          value != null && value.isNotEmpty
                              ? null
                              : "Name is required",
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: inputDecoration("Email"),
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (value) =>
                          value != null && value.contains("@")
                              ? null
                              : "Enter a valid email",
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: inputDecoration("Phone"),
                  keyboardType: TextInputType.phone,
                  validator:
                      (value) =>
                          value != null && value.isNotEmpty
                              ? null
                              : "Phone is required",
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: inputDecoration("Password"),
                  obscureText: true,
                  validator:
                      (value) =>
                          value != null && value.length >= 6
                              ? null
                              : "Password too short",
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
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
          decoration: inputDecoration("Friend's Email").copyWith(
            suffixIcon: IconButton(
              icon: Icon(Icons.add),
              onPressed: _addFriend,
            ),
          ),
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
    if (_step == 0 && _formKey.currentState!.validate()) {
      setState(() {
        _step = 1;
      });
    }
  }

  void _submit() {
    // Handle submit logic here
    print('Name: ${_nameController.text}');
    print('Email: ${_emailController.text}');
    print('Phone: ${_phoneController.text}');
    print('Password: ${_passwordController.text}');
    print('Invited Friends: $_invitedFriends');
  }
}
