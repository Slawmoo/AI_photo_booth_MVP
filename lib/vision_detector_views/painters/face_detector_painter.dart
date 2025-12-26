import 'dart:math' as math;
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
    this.overlayScale = 1.2,
    this.overlayYOffset = 0.8,
    this.overlayRotationOffset = 180.0,
  });

  final List<Face> faces;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final String selectedFilter;
  final ui.Image? filterImage;
  final double overlayScale;     // Multiplier for auto-scale
  final double overlayYOffset;   // Fraction of image height (0.0 = top, 1.0 = bottom of image)
  final double overlayRotationOffset;  // Manual rotation offset in degrees

  @override
  void paint(Canvas canvas, Size size) {
    for (final Face face in faces) {
      if (selectedFilter == 'None' ||
          filterImage == null ||
          face.landmarks[FaceLandmarkType.leftEye] == null ||
          face.landmarks[FaceLandmarkType.rightEye] == null) {
        continue;
      }

      final leftEye = face.landmarks[FaceLandmarkType.leftEye]!.position;
      final rightEye = face.landmarks[FaceLandmarkType.rightEye]!.position;
      final mouth = face.landmarks[FaceLandmarkType.bottomMouth]!.position;

      final leftEyeX = translateX(leftEye.x.toDouble(), size, imageSize, rotation, cameraLensDirection);
      final leftEyeY = translateY(leftEye.y.toDouble(), size, imageSize, rotation, cameraLensDirection);
      final rightEyeX = translateX(rightEye.x.toDouble(), size, imageSize, rotation, cameraLensDirection);
      final rightEyeY = translateY(rightEye.y.toDouble(), size, imageSize, rotation, cameraLensDirection);
      final mouthX = translateX(mouth.x.toDouble(), size, imageSize, rotation, cameraLensDirection);
      final mouthY = translateY(mouth.y.toDouble(), size, imageSize, rotation, cameraLensDirection);

      // Top of head position
      final topHead = FaceARUtils.reflectPointOverLine(
        lx: leftEyeX,
        ly: leftEyeY,
        rx: rightEyeX,
        ry: rightEyeY,
        mx: mouthX,
        my: mouthY,
      );

      // Head rotation
      final angleRadians = FaceARUtils.headAngle(
        lx: leftEyeX,
        ly: leftEyeY,
        rx: rightEyeX,
        ry: rightEyeY,
      ) * math.pi / 180;

      // Add manual offset to rotation
      final totalRotation = angleRadians + (overlayRotationOffset * math.pi / 180);

      // Auto-scale based on eye distance
      final eyeDist = math.sqrt(math.pow(rightEyeX - leftEyeX, 2) + math.pow(rightEyeY - leftEyeY, 2));
      final baseScale = (eyeDist / filterImage!.width.toDouble()) * overlayScale;

      // Anchor point (center bottom-ish of the overlay image)
      final double anchorX = filterImage!.width / 2;
      final double anchorY = filterImage!.height * (0.8 + overlayYOffset * 0.5).clamp(0.0, filterImage!.height.toDouble());

      canvas.save();
      canvas.translate(topHead['x']!, topHead['y']!);
      canvas.rotate(totalRotation);
      canvas.scale(baseScale);
      canvas.translate(-anchorX, -anchorY);
      canvas.drawImage(filterImage!, Offset.zero, Paint());
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
           oldDelegate.faces != faces ||
           oldDelegate.selectedFilter != selectedFilter ||
           oldDelegate.filterImage != filterImage ||
           oldDelegate.overlayScale != overlayScale ||
           oldDelegate.overlayYOffset != overlayYOffset ||
           oldDelegate.overlayRotationOffset != overlayRotationOffset;
  }
}