import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glacier/components/Button.dart';
import 'package:glacier/helpers/ToastHelper.dart';
import 'package:glacier/services/auth/sendPasswordResetEmail.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';
  final bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 10.0,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      'Enter your email to reset your password',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
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

                          const SizedBox(height: 24),
                          Button(
                            label: 'Send',
                            isLoading: _isLoading,
                            onPressed: _sendResetLink,
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: Container()),
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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // FlutterNativeSplash.remove();
  }

  Future<void> _sendResetLink() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await sendPasswordResetEmail(_emailController.text.trim());
      ToastHelper.showSuccess(
        context,
        message: 'Success.',
        description: 'Password reset email sent.',
      );
      Navigator.pop(context);

      // Navigate to home or next screen
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred';
        ToastHelper.showError(
          context,
          message: 'Reset email failed.',
          description: _errorMessage,
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
