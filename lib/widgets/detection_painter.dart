import 'dart:io';
import 'package:flutter/material.dart';
import '../models/detection_result.dart';

class DetectionPainter extends CustomPainter {
  final File imageFile;
  final List<DetectionResult> detections;
  final Size imageSize;

  DetectionPainter({
    required this.imageFile,
    required this.detections,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) {
      print('Canvas size is zero, skipping paint');
      return;
    }
    
    print('CustomPaint size: $size');
    print('Detections count: ${detections.length}');
    
    // Koordinatlar 0-1 arası normalize edilmiş
    final double scaleX = size.width;
    final double scaleY = size.height;

    for (var detection in detections) {
      // Box koordinatları: [x_center, y_center, width, height] - 0-1 arası normalize
      final box = detection.box;
      
      print('Drawing box: ${detection.className} at ${box}');
      
      // Koordinatları pixel'e çevir
      final double centerX = box[0] * scaleX;
      final double centerY = box[1] * scaleY;
      final double width = box[2] * scaleX;
      final double height = box[3] * scaleY;
      
      // Sol üst köşeyi hesapla
      final double left = centerX - width / 2;
      final double top = centerY - height / 2;
      
      print('Scaled rect: left=$left, top=$top, w=$width, h=$height');
      
      final rect = Rect.fromLTWH(left, top, width, height);
      
      // Sınıfa göre renk belirle
      final color = _getColorForClass(detection.className);
      
      // Box çiz
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      
      canvas.drawRect(rect, paint);
      
      // Arka plan çiz (label için)
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${detection.className} ${(detection.confidence * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      
      final bgRect = Rect.fromLTWH(
        left,
        top - 26,
        textPainter.width + 12,
        26,
      );
      
      final bgPaint = Paint()..color = color;
      canvas.drawRect(bgRect, bgPaint);
      
      // Label çiz
      textPainter.paint(canvas, Offset(left + 6, top - 22));
    }
  }

  Color _getColorForClass(String className) {
    print('Getting color for: "$className"');
    final trimmed = className.trim();
    
    if (trimmed == 'Cam') return Colors.green;
    if (trimmed == 'Metal') return Colors.grey;
    if (trimmed == 'Organik') return Colors.brown;
    if (trimmed == 'Kagit') return Colors.blue;
    if (trimmed == 'Plastik') return Colors.yellow.shade700;
    
    print('Unknown class "$trimmed", returning red!');
    return Colors.red;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
