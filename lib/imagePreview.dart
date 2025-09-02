import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  final String? imagePath; // Placeholder for captured image path

  const ImagePreview({super.key, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Preview'),
        centerTitle: true,
      ),
      body: Center(
        child: imagePath != null
            ? Text('Image: $imagePath') // Placeholder for image display
            : const Text('No image captured'),
      ),
    );
  }
}