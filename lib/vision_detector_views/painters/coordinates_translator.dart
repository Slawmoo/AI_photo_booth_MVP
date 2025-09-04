import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

double translateX(
  double x,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  double factor = canvasSize.width / imageSize.width;
  double newX = x * factor;
  if (cameraLensDirection == CameraLensDirection.front) {
    newX = canvasSize.width - newX; // Mirror horizontally for front camera
  }
  return newX;
}

double translateY(
  double y,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  double factor = canvasSize.height / imageSize.height;
  double newY = y * factor;
  // No vertical mirroring needed typically
  return newY;
}
