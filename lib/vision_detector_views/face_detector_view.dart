import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../image_preview.dart';
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

  final List<String> _filters = ['None', 'Hat', 'Eye-Patch', 'Beard', 'Christmas Cap'];
  String _selectedFilter = 'None';

  // All filter images stored here once loaded
  final Map<String, ui.Image> _filterImages = {};

  // Asset paths for both buttons and overlays
  final Map<String, String> _filterAssetPaths = {
    'None': 'assets/no_filter.png',
    'Hat': 'assets/hat.png',
    'Eye-Patch': 'assets/eye_patch.png',
    'Beard': 'assets/beard.png',
    'Christmas Cap': 'assets/xmas_cap.png',
  };

  // Track loading status
  bool _areImagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAllFilterImages();
  }

  Future<void> _loadAllFilterImages() async {
    final List<Future<void>> futures = [];

    for (final filter in _filters) {
      if (filter == 'None') continue;

      final path = _filterAssetPaths[filter]!;
      final future = DefaultAssetBundle.of(context)
          .load(path)
          .then((data) async {
        final bytes = data.buffer.asUint8List();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      }).then((image) {
        if (mounted) {
          setState(() {
            _filterImages[filter] = image;
          });
        }
      }).catchError((e) {
        debugPrint('Failed to load image for $filter: $e');
      });

      futures.add(future);
    }

    // Wait for all to complete
    await Future.wait(futures);

    if (mounted) {
      setState(() {
        _areImagesLoaded = true;
      });
    }
  }

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
      if (cameraController == null || !cameraController.value.isInitialized) {
        return;
      }

      final imageFile = await cameraController.takePicture();
      final imageBytes = await imageFile.readAsBytes();
      final uiImage = await decodeImageFromList(imageBytes);

      final inputImage = InputImage.fromFile(File(imageFile.path));
      final faces = await _faceDetector.processImage(inputImage);

      final currentFilterImage = _selectedFilter != 'None' ? _filterImages[_selectedFilter] : null;

      if (faces.isNotEmpty && currentFilterImage != null) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final size = Size(uiImage.width.toDouble(), uiImage.height.toDouble());

        canvas.drawImage(uiImage, Offset.zero, Paint());

        final painter = FaceDetectorPainter(
          faces,
          size,
          inputImage.metadata?.rotation ?? InputImageRotation.rotation0deg,
          _cameraLensDirection,
          selectedFilter: _selectedFilter,
          filterImage: currentFilterImage,
        );

        canvas.save();
        canvas.scale(-1.0, 1.0);
        canvas.translate(-size.width, 0);
        painter.paint(canvas, size);
        canvas.restore();

        final picture = recorder.endRecording();
        final img = await picture.toImage(uiImage.width, uiImage.height);
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        final processedBytes = byteData!.buffer.asUint8List();

        final processedFile = File('${imageFile.path}_with_filter.png');
        await processedFile.writeAsBytes(processedBytes);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImagePreview(
                imagePath: processedFile.path,
                gamma: _gamma,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImagePreview(
                imagePath: imageFile.path,
                gamma: _gamma,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
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

    // Optional: Show loading if images aren't ready yet
    if (!_areImagesLoaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFCF6565)),
        ),
      );
    }

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
        // Gamma button
        Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height / 2 - 184,
          child: FloatingActionButton.large(
            onPressed: _isCapturing ? null : () {
              setState(() {
                final currentIndex = _gammaOptions.indexOf(_gamma);
                _gamma = _gammaOptions[(currentIndex + 1) % _gammaOptions.length];
              });
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.brightness_6, color: Color(0xFFCF6565), size: 48),
          ),
        ),
        // Capture button
        Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height / 2 - 56,
          child: FloatingActionButton.large(
            onPressed: _isCapturing ? null : () async {
              if (_timerDelay == 0) {
                await _captureImage();
              } else {
                await _startCountdown(_timerDelay);
              }
            },
            backgroundColor: Colors.white,
            child: Icon(_isCapturing ? Icons.hourglass_empty : Icons.camera_alt,
                color: const Color(0xFFCF6565), size: 48),
          ),
        ),
        // Timer delay button
        Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height / 2 + 72,
          child: SizedBox(
            width: 90,
            height: 90,
            child: FloatingActionButton(
              onPressed: _isCapturing ? null : () {
                setState(() {
                  final currentIndex = _delayOptions.indexOf(_timerDelay);
                  _timerDelay = _delayOptions[(currentIndex + 1) % _delayOptions.length];
                });
              },
              backgroundColor: Colors.white,
              child: _timerDelay == 0
                  ? const Icon(Icons.timer, color: Color(0xFFCF6565), size: 38)
                  : Text('${_timerDelay}s',
                      style: const TextStyle(color: Color(0xFFCF6565), fontSize: 26, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        // Filter selection bar
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
                final filter = _filters[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedFilter == filter
                            ? const Color.fromARGB(204, 255, 255, 255)
                            : const Color.fromARGB(153, 255, 255, 255),
                      ),
                      child: Center(
                        child: Image.asset(
                          _filterAssetPaths[filter]!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error, color: Colors.red, size: 40);
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Countdown
        if (_countdown != null)
          Center(
            child: Text('$_countdown',
                style: const TextStyle(color: Color(0xFFCF6565), fontSize: 100, fontWeight: FontWeight.bold)),
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
    if (!_canProcess || !_areImagesLoaded) return;
    if (_isBusy) return;
    _isBusy = true;

    final faces = await _faceDetector.processImage(inputImage);

    if (inputImage.metadata?.size != null && inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(
        faces,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
        selectedFilter: _selectedFilter,
        filterImage: _filterImages[_selectedFilter],
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      _customPaint = null;
    }

    _isBusy = false;
    if (mounted) setState(() {});
  }
}