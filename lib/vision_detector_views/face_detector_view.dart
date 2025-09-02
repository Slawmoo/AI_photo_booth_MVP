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
  final List<int> _delayOptions = [0, 5, 10, 15];
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.front;

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
              builder: (context) => ImagePreview(imagePath: image.path),
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
    return Stack(
      children: [
        DetectorView(
          title: 'Face Detector',
          customPaint: _customPaint,
          text: _text,
          onImage: _processImage,
          initialCameraLensDirection: _cameraLensDirection,
          onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
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
          right: 16, // Aligned with shutter button
          top: MediaQuery.of(context).size.height / 2 + 72, // Below shutter (56 + 16 gap)
          child: Container(
            width: 90, // 20% smaller than 112dp
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
                      size: 38, // Scaled down 20% from 48
                    )
                  : Text(
                      '${_timerDelay}s',
                      style: const TextStyle(
                        color: Color(0xFFCF6565),
                        fontSize: 26, // Scaled down 20% from 32
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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