import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../imagePreview.dart';
import 'detector_view.dart';
import 'painters/face_detector_painter.dart';

class FaceDetectorView extends StatefulWidget {
  const FaceDetectorView({super.key});

  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  bool _isCapturing = false;
  int _timerDelay = 0;
  int? _countdown;
  double _gamma = 1.0;
  final List<double> _gammaOptions = [0.5, 1.0, 1.5, 2.0];
  final List<int> _delayOptions = [0, 5, 10, 15];
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.front;
  final List<String> _filters = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _captureImage() async {
    setState(() => _isCapturing = true);
    try {
      final cameraController = DetectorView.cameraController;
      if (cameraController != null && cameraController.value.isInitialized) {
        final image = await cameraController.takePicture();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImagePreview(
                imagePath: image.path,
                gamma: _gamma,
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _startCountdown(int delay) async {
    for (int i = delay; i >= 1; i--) {
      if (!mounted) return;
      setState(() {
        _countdown = i <= 3 ? i : null;
      });
      await Future.delayed(const Duration(seconds: 1));
    }
    setState(() => _countdown = null);
    if (mounted) {
      await _captureImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.matrix(_createGammaMatrix(_gamma)),
          child: DetectorView(
            title: 'Face Detector',
            customPaint: _customPaint,
            text: _text,
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
          ),
        ),
        Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height / 2 - 184,
          child: FloatingActionButton.large(
            onPressed: _isCapturing
                ? null
                : () {
                    setState(() {
                      _gamma = _gammaOptions[(_gammaOptions.indexOf(_gamma) + 1) % _gammaOptions.length];
                    });
                  },
            backgroundColor: Colors.white,
            child: Icon(
              Icons.brightness_6,
              color: const Color(0xFFCF6565),
              size: 48,
            ),
          ),
        ),
        Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height / 2 - 56,
          child: FloatingActionButton.large(
            onPressed: _isCapturing
                ? null
                : () async {
                    if (_timerDelay == 0) {
                      await _captureImage();
                    } else {
                      await _startCountdown(_timerDelay);
                    }
                  },
            backgroundColor: Colors.white,
            child: Icon(
              _isCapturing ? Icons.hourglass_empty : Icons.camera_alt,
              color: const Color(0xFFCF6565),
              size: 48,
            ),
          ),
        ),
        Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height / 2 + 72,
          child: Container(
            width: 90,
            height: 90,
            child: FloatingActionButton(
              onPressed: _isCapturing
                  ? null
                  : () {
                      setState(() {
                        _timerDelay = _delayOptions[(_delayOptions.indexOf(_timerDelay) + 1) % _delayOptions.length];
                      });
                    },
              backgroundColor: Colors.white,
              child: _timerDelay == 0
                  ? Icon(
                      Icons.timer,
                      color: const Color(0xFFCF6565),
                      size: 38,
                    )
                  : Text(
                      '${_timerDelay}s',
                      style: const TextStyle(
                        color: Color(0xFFCF6565),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: (screenWidth - screenWidth * 0.45) / 2,
          right: (screenWidth - screenWidth * 0.45) / 2,
          child: SizedBox(
            height: 100,
            width: screenWidth * 0.45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Apply filter later
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      child: Center(
                        child: Text(
                          _filters[index],
                          style: const TextStyle(
                            color: Color(0xFFCF6565),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_countdown != null)
          Center(
            child: Text(
              '$_countdown',
              style: const TextStyle(
                color: Color(0xFFCF6565),
                fontSize: 100,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
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

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.metadata?.size != null && inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(
        faces,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}