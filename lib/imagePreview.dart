import 'package:flutter/material.dart';
import 'dart:io';

class ImagePreview extends StatelessWidget {
  final String? imagePath;
  final double gamma; // Added gamma parameter

  const ImagePreview({super.key, this.imagePath, this.gamma = 1.0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Preview'),
        centerTitle: true,
      ),
      body: Center(
        child: imagePath != null
            ? ColorFiltered(
                colorFilter: ColorFilter.matrix(_createGammaMatrix(gamma)),
                child: Image.file(File(imagePath!)),
              )
            : const Text('No image captured'),
      ),
    );
  }

  List<double> _createGammaMatrix(double gamma) {
    double invGamma = 1.0 / gamma;
    return [
      invGamma, 0, 0, 0, 0,
      0, invGamma, 0, 0, 0,
      0, 0, invGamma, 0, 0,
      0, 0, 0, 1.0, 0,
    ];
  }
}