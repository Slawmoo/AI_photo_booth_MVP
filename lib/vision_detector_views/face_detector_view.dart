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

  final Map<String, ui.Image> _filterImages = {};

  final Map<String, String> _filterAssetPaths = {
    'None': 'assets/no_filter.png',
    'Hat': 'assets/hat.png',
    'Eye-Patch': 'assets/eye_patch.png',
    'Beard': 'assets/beard.png',
    'Christmas Cap': 'assets/xmas_cap.png',
  };

  bool _areImagesLoaded = false;

  // Adjustable parameters
  double _overlayScale = 1.2;        // Base scale multiplier
  double _overlayYOffset = 0.8;      // Fraction of image height from bottom
  double _overlayRotationOffset = 180.0;  // Manual rotation offset in degrees (default 180 to fix upside down)

  // Filter-specific defaults (tuned based on your testing)
  final Map<String, double> _defaultOverlayScales = {
    'Hat': 3.5,
    'Eye-Patch': 1.6,
    'Beard': 2.5,
    'Christmas Cap': 3.3,
  };

  final Map<String, double> _defaultOverlayYOffsets = {
    'Hat': 0.0,
    'Eye-Patch': -0.5,
    'Beard': -0.4,
    'Christmas Cap': -0.9,
  };

  final Map<String, double> _defaultOverlayRotationOffsets = {
    'Hat': 180.0,
    'Eye-Patch': 180.0,
    'Beard': 180.0,
    'Christmas Cap': 200.0,
  };

  @override
  void initState() {
    super.initState();
    _loadAllFilterImages();
  }

  Future<void> _loadAllFilterImages() async {
    final List<Future<void>> futures = [];
    final Map<String, String> loadErrors = {};

    for (final filter in _filters) {
      if (filter == 'None') continue;

      final path = _filterAssetPaths[filter]!;
      debugPrint('Loading filter: $filter from $path');

      final future = DefaultAssetBundle.of(context)
          .load(path)
          .then((data) => data.buffer.asUint8List())
          .then((bytes) => ui.instantiateImageCodec(bytes))
          .then((codec) => codec.getNextFrame())
          .then((frame) {
            if (mounted) {
              setState(() {
                _filterImages[filter] = frame.image;
              });
            }
          })
          .catchError((e) {
            final msg = 'Failed to load $filter: $e';
            debugPrint(msg);
            loadErrors[filter] = msg;
          });

      futures.add(future);
    }

    await Future.wait(futures);

    if (mounted) {
      setState(() => _areImagesLoaded = true);

      if (loadErrors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All filters loaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Load errors: ${loadErrors.keys.join(', ')}'),
            duration: const Duration(seconds: 8),
          ),
        );
      }
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
      if (cameraController == null || !cameraController.value.isInitialized) return;

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
          overlayScale: _overlayScale,
          overlayYOffset: _overlayYOffset,
          overlayRotationOffset: _overlayRotationOffset,
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
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _startCountdown(int delay) async {
    for (int i = delay; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _countdown = i <= 3 ? i : null);
      await Future.delayed(const Duration(seconds: 1));
    }
    setState(() => _countdown = null);
    if (mounted) await _captureImage();
  }

  void _showSlidersMenu() {
  showDialog(
    context: context,
    builder: (context) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.all(20),
            width: 220,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5), // 50% opacity background
              borderRadius: BorderRadius.circular(20),
            ),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Close button with 50% opacity
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        color: Colors.white.withOpacity(0.5),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Scale Slider
                    _buildSliderRow(
                      value: _overlayScale,
                      min: 1.0,
                      max: 4.0,
                      divisions: 60,
                      icon: Icons.zoom_out_map, // Scaling icon
                      onChanged: (value) {
                        setDialogState(() => _overlayScale = value);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 32),

                    // Height (Y Offset) Slider
                    _buildSliderRow(
                      value: _overlayYOffset,
                      min: -3.0,
                      max: 1.0,
                      divisions: 40,
                      icon: Icons.height, // Up/down arrows
                      onChanged: (value) {
                        setDialogState(() => _overlayYOffset = value);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 32),

                    // Rotation Slider
                    _buildSliderRow(
                      value: _overlayRotationOffset,
                      min: 0.0,
                      max: 360.0,
                      divisions: 72,
                      icon: Icons.rotate_90_degrees_ccw, // Circular rotation arrows
                      onChanged: (value) {
                        setDialogState(() => _overlayRotationOffset = value);
                        setState(() {});
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
    barrierColor: Colors.transparent,
    barrierDismissible: true,
  );
}

// Helper method to build each slider row
Widget _buildSliderRow({
  required double value,
  required double min,
  required double max,
  required int divisions,
  required IconData icon,
  required ValueChanged<double> onChanged,
}) {
  return Row(
    children: [
      Expanded(
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: const Color(0xFFCF6565),
          inactiveColor: Colors.white.withOpacity(0.3),
          onChanged: onChanged,
        ),
      ),
      const SizedBox(width: 12),
      Icon(
        icon,
        color: Colors.white,
        size: 32,
        weight: 700, // Bold icon
      ),
    ],
  );
}
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (!_areImagesLoaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFCF6565))),
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

        // Replace the old "Sliders >" button with this new half-rectangle trigger
        Positioned(
          left: 16,
          top: screenHeight / 2 - 40,
          child: GestureDetector(
            onTap: _showSlidersMenu,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(30)),
              child: Container(
                width: 60,
                height: 80,
                color: Colors.black.withOpacity(0.6), // 60% opacity
                child: const Center(
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Right side buttons (gamma, capture, timer)
        Positioned(
          right: 16,
          top: screenHeight / 2 - 184,
          child: FloatingActionButton.large(
            onPressed: _isCapturing ? null : () {
              setState(() {
                final idx = _gammaOptions.indexOf(_gamma);
                _gamma = _gammaOptions[(idx + 1) % _gammaOptions.length];
              });
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.brightness_6, color: Color(0xFFCF6565), size: 48),
          ),
        ),
        Positioned(
          right: 16,
          top: screenHeight / 2 - 56,
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
        Positioned(
          right: 16,
          top: screenHeight / 2 + 72,
          child: SizedBox(
            width: 90,
            height: 90,
            child: FloatingActionButton(
              onPressed: _isCapturing ? null : () {
                setState(() {
                  final idx = _delayOptions.indexOf(_timerDelay);
                  _timerDelay = _delayOptions[(idx + 1) % _delayOptions.length];
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

        // Bottom filter bar - updated onTap
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
                    onTap: () => setState(() {
                      _selectedFilter = filter;
                      if (filter != 'None') {
                        _overlayScale = _defaultOverlayScales[filter] ?? 1.2;
                        _overlayYOffset = _defaultOverlayYOffsets[filter] ?? 0.8;
                        _overlayRotationOffset = _defaultOverlayRotationOffsets[filter] ?? 180.0;
                      }
                    }),
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
                          errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.red),
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
    if (!_canProcess || !_areImagesLoaded || _isBusy) return;
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
        overlayScale: _overlayScale,
        overlayYOffset: _overlayYOffset,
        overlayRotationOffset: _overlayRotationOffset,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      _customPaint = null;
    }

    _isBusy = false;
    if (mounted) setState(() {});
  }
}