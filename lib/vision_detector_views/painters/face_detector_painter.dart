//import 'dart:math'; //ENABLE FOR ADDING NEW FILTERS
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
    /*
    //ENABLE FOR ADDING NEW FILTERS DOWN IS MORE TO ENABLE
    final Paint paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.red;
    final Paint paint2 = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0
      ..color = Colors.green;
    final Paint paint3 = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0
      ..color = const ui.Color.fromARGB(255, 1, 35, 229);*/
    for (final Face face in faces) {
      /*final left = translateX(
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
      );*/
      
      //ENABLE FOR ADDING NEW FILTERS UP IS MORE TO ENABLE
      /*
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

      void paintLandmark(FaceLandmarkType type) {        final landmark = face.landmarks[type];
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

      /*void paintTestmark(double x, double y) {
          canvas.drawCircle(
              Offset(
                translateX(
                  x,
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
                translateY(
                  y,
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
              ),
              3,
              paint3);
        }
      */
      for (final type in FaceContourType.values) {
        paintContour(type);
      }

      for (final type in FaceLandmarkType.values) {
        paintLandmark(type);
      }*/

      
      //paintTestmark(FaceLandmarkType.bottomMouth);

      // TESTING
        // Use topHead['x'], topHead['y'], and angle to position/rotate hat
        // Example: Position hat at topHead with angle rotation
        // Adjust hat size: width = 1.2 * faceWidth, y = topHead['y'] - (hatHeight * 0.3)
      
      if (selectedFilter == 'Hat' && hatImage != null && face.landmarks[FaceLandmarkType.leftEye] != null && face.landmarks[FaceLandmarkType.rightEye] != null) {
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
        //paintTestmark(topHead['x']!, topHead['y']!);
        // Get head angle for hat rotation
        /*final angle = FaceARUtils.headAngle(
          lx: leftEyeX,
          ly: leftEyeY,
          rx: rightEyeX,
          ry: rightEyeY,
        );*/
        
        canvas.save();
        canvas.translate(topHead['x']! - (0.5*hatImage!.width.toDouble()), topHead['y']! -(0.8 * hatImage!.height.toDouble())); // OVO MJENJAMO

        // Draw the hat image
        final imageRect = Rect.fromLTWH(0, 0, hatImage!.width.toDouble(), hatImage!.height.toDouble());
        canvas.drawImage(hatImage!, imageRect.topLeft, Paint());
        /* //PICTURE PLACEMENT DEBUGGING
        // Draw canvas outline (semi-transparent rectangle)
        final outlinePaint = Paint()
          ..color = ui.Color.fromARGB(50, 0, 0, 0) // Fully transparent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRect(imageRect, outlinePaint);

        // TP (Top Left)
        final tpTextBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textDirection: TextDirection.ltr,
          maxLines: 1,
        ))
          ..pushStyle(ui.TextStyle(fontSize: 12.0))
          ..addText('TP');
        var paragraph = tpTextBuilder.build();
        paragraph.layout(const ui.ParagraphConstraints(width: 20));
        canvas.drawParagraph(paragraph, Offset(-10, -15));

        // BL (Bottom Left)
        final blTextBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textDirection: TextDirection.ltr,
          maxLines: 1,
        ))
          ..pushStyle(ui.TextStyle(fontSize: 12.0))
          ..addText('BL');
        paragraph = blTextBuilder.build();
        paragraph.layout(const ui.ParagraphConstraints(width: 20));
        canvas.drawParagraph(paragraph, Offset(-10, hatImage!.height.toDouble() + 5));

        // TR (Top Right)
        final trTextBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textDirection: TextDirection.ltr,
          maxLines: 1,
        ))
          ..pushStyle(ui.TextStyle(fontSize: 12.0))
          ..addText('TR');
        paragraph = trTextBuilder.build();
        paragraph.layout(const ui.ParagraphConstraints(width: 20));
        canvas.drawParagraph(paragraph, Offset(hatImage!.width.toDouble() - 10, -15));

        // BR (Bottom Right)
        final brTextBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textDirection: TextDirection.ltr,
          maxLines: 1,
        ))
          ..pushStyle(ui.TextStyle(fontSize: 12.0))
          ..addText('BR');
        paragraph = brTextBuilder.build();
        paragraph.layout(const ui.ParagraphConstraints(width: 20));
        canvas.drawParagraph(paragraph, Offset(hatImage!.width.toDouble() - 10, hatImage!.height.toDouble() + 5));
        */
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
