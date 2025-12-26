import 'package:flutter/material.dart';
import 'dart:io';

class ImagePreview extends StatelessWidget {
  final String? imagePath;
  final double gamma;

  const ImagePreview({
    super.key,
    this.imagePath,
    this.gamma = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen image with gamma correction and horizontal flip
          if (imagePath != null)
            Center(
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_createGammaMatrix(gamma)),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(-1.0, 1.0), // Mirror flip
                  child: Image.file(
                    File(imagePath!),
                    fit: BoxFit.contain, // Maximally scales to fit screen while preserving aspect ratio
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            )
          else
            const Center(
              child: Text(
                'No image captured',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),

          // Top-left: Back button
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildActionButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // Top-right: Share button (placeholder)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildActionButton(
                  icon: Icons.share_rounded,
                  onPressed: () {
                    // TODO: Implement share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share feature coming soon!')),
                    );
                  },
                ),
              ),
            ),
          ),

          // Bottom-right: Print button (placeholder)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildActionButton(
                  icon: Icons.print_rounded,
                  onPressed: () {
                    // TODO: Implement print functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Print feature coming soon!')),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable sleek button with rounded rectangle and 70% opacity
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
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