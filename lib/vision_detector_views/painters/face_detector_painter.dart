import 'dart:math';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'coordinates_translator.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(
    this.faces,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection, {
    this.selectedFilter = 'None',
    this.hatImage,
  });

  final List<Face> faces;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final String selectedFilter;
  final ui.Image? hatImage;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.red;
    final Paint paint2 = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0
      ..color = Colors.green;

    for (final Face face in faces) {
      final left = translateX(
        face.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        face.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        face.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        face.boundingBox.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint1,
      );

      void paintContour(FaceContourType type) {
        final contour = face.contours[type];
        if (contour?.points != null) {
          for (final Point point in contour!.points) {
            canvas.drawCircle(
                Offset(
                  translateX(
                    point.x.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                  translateY(
                    point.y.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                ),
                1,
                paint1);
          }
        }
      }

      void paintLandmark(FaceLandmarkType type) {
        final landmark = face.landmarks[type];
        if (landmark?.position != null) {
          canvas.drawCircle(
              Offset(
                translateX(
                  landmark!.position.x.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
                translateY(
                  landmark.position.y.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
              ),
              2,
              paint2);
        }
      }

      for (final type in FaceContourType.values) {
        paintContour(type);
      }

      for (final type in FaceLandmarkType.values) {
        paintLandmark(type);
      }

      if (selectedFilter == 'Hat' && hatImage != null && face.landmarks[FaceLandmarkType.leftEar] != null && face.landmarks[FaceLandmarkType.rightEar] != null && face.landmarks[FaceLandmarkType.leftEye] != null && face.landmarks[FaceLandmarkType.rightEye] != null) {
        final leftEar = face.landmarks[FaceLandmarkType.leftEar]!.position;
        final rightEar = face.landmarks[FaceLandmarkType.rightEar]!.position;
        final leftEyebrow = face.landmarks[FaceLandmarkType.leftEye]!.position;
        final rightEyebrow = face.landmarks[FaceLandmarkType.rightEye]!.position;

        final leftEarX = translateX(leftEar.x.toDouble(), size, imageSize, rotation, cameraLensDirection);
        final leftEarY = translateY(leftEar.y.toDouble(), size, imageSize, rotation, cameraLensDirection);
        final rightEarX = translateX(rightEar.x.toDouble(), size, imageSize, rotation, cameraLensDirection);
        final rightEarY = translateY(rightEar.y.toDouble(), size, imageSize, rotation, cameraLensDirection);
        final leftEyebrowX = translateX(leftEyebrow.x.toDouble(), size, imageSize, rotation, cameraLensDirection);
        final leftEyebrowY = translateY(leftEyebrow.y.toDouble(), size, imageSize, rotation, cameraLensDirection);
        final rightEyebrowX = translateX(rightEyebrow.x.toDouble(), size, imageSize, rotation, cameraLensDirection);
        final rightEyebrowY = translateY(rightEyebrow.y.toDouble(), size, imageSize, rotation, cameraLensDirection);

        final foreheadX = (leftEyebrowX + rightEyebrowX) / 2;
        final foreheadY = (leftEyebrowY + rightEyebrowY) / 2;

        final headWidth = (leftEarX - rightEarX).abs();
        final imageWidth = headWidth * 1.5;
        final imageHeight = imageWidth * (hatImage!.height.toDouble() / hatImage!.width.toDouble());

        final centerX = (leftEarX + rightEarX) / 2;
        final centerY = foreheadY - headWidth * 0.3;

        final angle = (face.headEulerAngleY ?? 0.0) * pi / 180;

        canvas.save();
        canvas.translate(centerX, centerY);
        canvas.rotate(angle);
        final imageRect = Rect.fromLTWH(-imageWidth / 2, -imageHeight / 2, imageWidth, imageHeight);
        canvas.drawImage(hatImage!, imageRect.topLeft, Paint());
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
           oldDelegate.faces != faces ||
           oldDelegate.selectedFilter != selectedFilter ||
           oldDelegate.hatImage != hatImage;
  }
}