import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_access_service.dart';
import 'list_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: UserAccessService.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _CenteredStatus(message: 'Checking account');
        }

        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        return StreamBuilder<AppUserAccess?>(
          stream: UserAccessService.instance.watchCurrentAccess(),
          builder: (context, accessSnapshot) {
            if (accessSnapshot.connectionState == ConnectionState.waiting) {
              return const _CenteredStatus(message: 'Loading permissions');
            }

            final access = accessSnapshot.data;
            if (access == null || !access.approved) {
              return PendingApprovalScreen(email: authSnapshot.data?.email);
            }

            return ListScreen(access: access);
          },
        );
      },
    );
  }
}

class PendingApprovalScreen extends StatelessWidget {
  final String? email;

  const PendingApprovalScreen({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 64,
                  color: Color(0xFF1B5E20),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Waiting for admin approval',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF143D18),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  email == null
                      ? 'Your account has been created. Ask an admin to approve it.'
                      : '$email has been created. Ask an admin to approve it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: UserAccessService.instance.signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredStatus extends StatelessWidget {
  final String message;

  const _CenteredStatus({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF1B5E20)),
            const SizedBox(height: 18),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF143D18),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
