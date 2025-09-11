import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glacier/components/Button.dart';
import 'package:glacier/services/auth/signin.dart';
import 'package:glacier/themes/theme_extensions.dart';
import 'package:toastification/toastification.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  _SigninPageState createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 0.0,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60.0,
                        vertical: 0,
                      ),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              errorText:
                                  _errorMessage.isNotEmpty
                                      ? _errorMessage
                                      : null,
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Email is required'
                                        : value.contains('@')
                                        ? null
                                        : 'Invalid email',
                            onTapOutside: (event) {
                              FocusScope.of(context).unfocus();
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
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
                              errorText:
                                  _errorMessage.isNotEmpty
                                      ? _errorMessage
                                      : null,
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Password is required'
                                        : value.length >= 6
                                        ? null
                                        : 'Password too short',

                            onTapOutside: (event) {
                              FocusScope.of(context).unfocus();
                            },
                          ),
                          const SizedBox(height: 24),
                          Button(
                            label: 'Sign In',
                            isLoading: _isLoading,
                            onPressed: _signIn,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account?",
                                    style: TextStyle(color: Colors.blueAccent),
                                  ),
                                  const Text(
                                    " Sign up",
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // FlutterNativeSplash.remove();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await signin(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Navigate to home or next screen
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred';
        toastification.show(
          title: Text('Sign-in failed.'),
          description: Text(" ${_errorMessage.toString()}"),
          autoCloseDuration: const Duration(seconds: 5),
          type: ToastificationType.error,
          alignment: Alignment.bottomCenter,
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
