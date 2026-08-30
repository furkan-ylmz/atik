import 'dart:math';
import 'package:flutter/material.dart';
import '../../../data/models/detection_result_model.dart';

class DetectionBoundingBoxPainter extends CustomPainter {
  final List<DetectionResultModel> detections;
  final Size? imageSize;

  const DetectionBoundingBoxPainter({
    required this.detections,
    this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || detections.isEmpty) return;

    // Resmin canvas içinde fit: contain ile kapladığı gerçek alanı hesapla
    double renderWidth = size.width;
    double renderHeight = size.height;
    double offsetX = 0.0;
    double offsetY = 0.0;

    if (imageSize != null && imageSize!.width > 0 && imageSize!.height > 0) {
      final double scale = min(
        size.width / imageSize!.width,
        size.height / imageSize!.height,
      );
      renderWidth = imageSize!.width * scale;
      renderHeight = imageSize!.height * scale;
      offsetX = (size.width - renderWidth) / 2.0;
      offsetY = (size.height - renderHeight) / 2.0;
    }

    for (final detection in detections) {
      final box = detection.box;
      if (box.length < 4) continue;

      // 0..1 normalize koordinatları resmin render alanına ölçekle
      final double centerX = offsetX + (box[0] * renderWidth);
      final double centerY = offsetY + (box[1] * renderHeight);
      final double width = box[2] * renderWidth;
      final double height = box[3] * renderHeight;

      final double left = centerX - width / 2.0;
      final double top = centerY - height / 2.0;

      final rect = Rect.fromLTWH(left, top, width, height);
      final color = detection.category.color;

      // 1. Kutu Çizgisi
      final boxPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(rrect, boxPaint);

      // 2. Kutu İçi Şeffaf Dolgu
      final fillPaint = Paint()
        ..color = color.withOpacity(0.12)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, fillPaint);

      // 3. Etiket ve Yüzde Yazısı
      final textSpan = TextSpan(
        text: '${detection.category.displayName} ${detection.formattedConfidence}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      const double badgePaddingH = 8.0;
      const double badgePaddingV = 4.0;
      final double badgeWidth = textPainter.width + (badgePaddingH * 2);
      final double badgeHeight = textPainter.height + (badgePaddingV * 2);

      // Etiket pozisyonu (kutu dışına taşarsa kutu içine çek)
      double badgeTop = top - badgeHeight - 2;
      if (badgeTop < offsetY) {
        badgeTop = top + 2;
      }
      final double badgeLeft = left.clamp(offsetX, offsetX + renderWidth - badgeWidth);

      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeLeft, badgeTop, badgeWidth, badgeHeight),
        const Radius.circular(6),
      );

      final badgePaint = Paint()..color = color;
      canvas.drawRRect(badgeRect, badgePaint);

      textPainter.paint(
        canvas,
        Offset(badgeLeft + badgePaddingH, badgeTop + badgePaddingV),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DetectionBoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections || oldDelegate.imageSize != imageSize;
  }
}
