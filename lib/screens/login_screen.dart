import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_access_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _registerMode = false;
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (_registerMode) {
        await UserAccessService.instance.register(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      } else {
        await UserAccessService.instance.signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(_messageForAuthError(e));
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFC62828),
      ),
    );
  }

  String _messageForAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'That email already has an account.';
      case 'weak-password':
        return 'Use a stronger password.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/logo/logo.png',
                        width: 86,
                        height: 86,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'SMP Site Assessment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF143D18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _registerMode
                          ? 'Create an account for admin approval'
                          : 'Sign in to access field records',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_registerMode) ...[
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.badge_outlined),
                          labelText: 'Name',
                        ),
                        validator: (value) {
                          if (!_registerMode) return null;
                          final name = value?.trim() ?? '';
                          if (name.length < 2) return 'Name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.mail_outline),
                        labelText: 'Email',
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (!email.contains('@')) return 'Email is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline),
                        labelText: 'Password',
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 6) {
                          return 'Use at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _busy ? null : _submit,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(_registerMode ? Icons.person_add : Icons.login),
                      label: Text(_registerMode ? 'Create account' : 'Sign in'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _registerMode = !_registerMode;
                              }),
                      child: Text(
                        _registerMode
                            ? 'Already approved? Sign in'
                            : 'Need access? Create account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
