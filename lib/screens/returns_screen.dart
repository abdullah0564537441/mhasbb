// lib/screens/returns_screen.dart
import 'package:flutter/material.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شاشة المرتجعات'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('هذه شاشة قائمة المرتجعات'),
      ),
    );
  }
}
