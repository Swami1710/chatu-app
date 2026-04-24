import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/login_screen.dart';
import 'screens/setup_profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(); // 🔥 Firebase init
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chatu 💬',
      theme: ThemeData.dark(),

      // 🔥 Entry point (decides login/home automatically)
      home: const SplashScreen(),

      routes: {
        '/login': (_) => const LoginScreen(),
        '/setup': (_) => const SetupProfileScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}