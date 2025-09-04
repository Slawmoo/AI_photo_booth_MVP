import 'dart:math';

class FaceARUtils {
  static Map<String, double> reflectPointOverLine({
    required double lx, // leftEye x
    required double ly, // leftEye y
    required double rx, // rightEye x
    required double ry, // rightEye y
    required double mx, // bottomMouth x
    required double my, // bottomMouth y
  }) {
    // Vector from left to right eye
    final dx = rx - lx;
    final dy = ry - ly;

    // Project mouth onto eye line
    final t = ((mx - lx) * dx + (my - ly) * dy) / (dx * dx + dy * dy);
    final projX = lx + t * dx;
    final projY = ly + t * dy;

    // Reflection: 2*proj - mouth
    final topX = 2 * projX - mx;
    final topY = 2 * projY - my;

    return {'x': topX, 'y': topY};
  }

  // Angle of eye line (for hat rotation, in degrees)
  static double headAngle({
    required double lx, // leftEye x
    required double ly, // leftEye y
    required double rx, // rightEye x
    required double ry, // rightEye y
  }) {
    return (atan2(ry - ly, rx - lx) * 180 / pi);
  }
}