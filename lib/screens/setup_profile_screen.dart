import 'package:flutter/material.dart';

class SetupProfileScreen extends StatelessWidget {
  const SetupProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Profile")),
      body: const Center(
        child: Text("Setup Profile Screen 🔥"),
      ),
    );
  }
}