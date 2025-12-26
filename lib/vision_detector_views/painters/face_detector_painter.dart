import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'coordinates_translator.dart';
import '/face_ar_utils.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(
    this.faces,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection, {
    this.selectedFilter = 'None',
    this.filterImage,
  });

  final List<Face> faces;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final String selectedFilter;
  final ui.Image? filterImage;

  @override
  void paint(Canvas canvas, Size size) {
    for (final Face face in faces) {
      if (selectedFilter != 'None' && filterImage != null && face.landmarks[FaceLandmarkType.leftEye] != null && face.landmarks[FaceLandmarkType.rightEye] != null) {
        final leftEye = face.landmarks[FaceLandmarkType.leftEye]!.position;
        final rightEye = face.landmarks[FaceLandmarkType.rightEye]!.position;
        final mouth = face.landmarks[FaceLandmarkType.bottomMouth]!.position;

        final leftEyeX = translateX(leftEye.x.toDouble(), size, imageSize, rotation, cameraLensDirection);
        final leftEyeY = translateY(leftEye.y.toDouble(), size, imageSize, rotation, cameraLensDirection);
        final rightEyeX = translateX(rightEye.x.toDouble(), size, imageSize, rotation, cameraLensDirection);
        final rightEyeY = translateY(rightEye.y.toDouble(), size, imageSize, rotation, cameraLensDirection);
        final mouthX = translateX(mouth.x.toDouble(), size, imageSize, rotation, cameraLensDirection);
        final mouthY = translateY(mouth.y.toDouble(), size, imageSize, rotation, cameraLensDirection);

        // Calculate top of head position
        final topHead = FaceARUtils.reflectPointOverLine(
          lx: leftEyeX,
          ly: leftEyeY,
          rx: rightEyeX,
          ry: rightEyeY,
          mx: mouthX,
          my: mouthY,
        );

        canvas.save();
        canvas.translate(topHead['x']! - (0.5 * filterImage!.width.toDouble()), topHead['y']! - (0.8 * filterImage!.height.toDouble()));

        // Draw the filter image
        final imageRect = Rect.fromLTWH(0, 0, filterImage!.width.toDouble(), filterImage!.height.toDouble());
        canvas.drawImage(filterImage!, imageRect.topLeft, Paint());

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
           oldDelegate.faces != faces ||
           oldDelegate.selectedFilter != selectedFilter ||
           oldDelegate.filterImage != filterImage;
  }
}