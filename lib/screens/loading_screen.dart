import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../firebase_options.dart';
import 'auth_gate.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _startApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startApp() async {
    await Future.wait([
      _initializeServices(),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _initializeServices() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      unawaited(DatabaseHelper.instance.syncUnsyncedToFirestore());
      unawaited(DatabaseHelper.instance.syncFromFirestore());
    } catch (_) {
      // The app remains available when Firebase is unavailable or offline.
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final logoSize = size.shortestSide.clamp(96.0, 132.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: logoSize,
                    height: logoSize,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B5E20).withValues(alpha: 0.14),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'SMP Site Assessment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF143D18),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preparing workspace',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
