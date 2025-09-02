import 'package:flutter/material.dart';
import 'landing_page.dart';

void main() {
  runApp(const HomeTab());
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'AI Photo Booth',
      debugShowCheckedModeBanner: false,
      home: AIPhotoBoothHomePage(),
    );
  }
}