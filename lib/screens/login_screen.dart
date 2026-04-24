import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService authService = AuthService();
  bool isLoading = false;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _fade = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _scale = Tween(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      final user = await authService.signInWithGoogle();

      if (!mounted) return;

      if (user != null) {
        final allowed = await authService.isUserAllowed(user.email!);

        if (!mounted) return;

        if (!allowed) {
          await authService.logout();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Access Denied ❌")),
          );
          setState(() => isLoading = false);
          return;
        }

        String? fcmToken =
        await FirebaseMessaging.instance.getToken();

        final isFirst = await authService.isFirstTime(user);

        if (!mounted) return;

        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .set({
          "name": user.displayName,
          "email": user.email,
          "photoUrl": user.photoURL,
          "uid": user.uid,
          "isOnline": true,
          "lastSeen": DateTime.now(),
          "fcmToken": fcmToken,
        }, SetOptions(merge: true));

        if (isFirst) {
          Navigator.pushReplacementNamed(context, '/setup');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF2C5364),
              Color(0xFF000000),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔥 APP LOGO
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.6),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 110,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🔥 TITLE
                  const Text(
                    "Chatu 💬",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Connect • Chat • Chill",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 🔥 BUTTON
                  isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : GestureDetector(
                    onTap: login,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF833AB4),
                            Color(0xFFFD1D1D),
                            Color(0xFFFCAF45),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.login, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            "Login with Google",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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