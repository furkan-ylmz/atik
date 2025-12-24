import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/detection_result.dart';

class DetectionService {
  static Interpreter? _interpreter;
  static List<String>? _labels;
  static const int inputSize = 640;
  static const double confidenceThreshold = 0.75;

  static Future<void> initialize() async {
    try {
      // Model yükle
      _interpreter = await Interpreter.fromAsset('assets/best_float32.tflite');
      
      // Etiketleri yükle
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      print('Model yüklendi: ${_interpreter!.getInputTensors()}');
      print('Etiketler yüklendi: $_labels');
    } catch (e) {
      print('Model yükleme hatası: $e');
      rethrow;
    }
  }

  static Future<List<DetectionResult>> detectObjects(String imagePath) async {
    if (_interpreter == null || _labels == null) {
      await initialize();
    }

    try {
      // Input tensor shape'ini kontrol et
      final inputShape = _interpreter!.getInputTensor(0).shape;
      print('Input shape: $inputShape');
      
      // Resmi yükle ve ön işle
      final imageData = await _preprocessImage(imagePath);
      
      // Output tensor shape'ini kontrol et
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      print('Output shape: $outputShape');
      
      // Output buffer oluştur
      var output = List.generate(
        outputShape[0],
        (i) => List.generate(
          outputShape[1],
          (j) => List.generate(
            outputShape[2],
            (k) => 0.0,
          ),
        ),
      );
      
      // Model çalıştır
      _interpreter!.run(imageData, output);
      
      // Sonuçları parse et
      final detections = _parseOutput(output, outputShape);
      
      return detections;
    } catch (e) {
      print('Tespit hatası: $e');
      return [];
    }
  }

  static Future<List<List<List<List<double>>>>> _preprocessImage(String imagePath) async {
    // Resmi oku
    final imageBytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);
    
    if (image == null) {
      throw Exception('Resim yüklenemedi');
    }

    // 640x640'a yeniden boyutlandır
    img.Image resizedImage = img.copyResize(image, width: inputSize, height: inputSize);
    
    // YOLOv8 formatı: [1, 640, 640, 3] (BHWC format)
    var input = List.generate(
      1,
      (b) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) => List.generate(
            3,
            (c) {
              final pixel = resizedImage.getPixel(x, y);
              if (c == 0) return pixel.r / 255.0;
              if (c == 1) return pixel.g / 255.0;
              return pixel.b / 255.0;
            },
          ),
        ),
      ),
    );

    return input;
  }

  static List<DetectionResult> _parseOutput(List output, List<int> shape) {
    List<DetectionResult> detections = [];
    
    print('Parsing output with shape: $shape');
    
    // YOLOv8 çıktı formatı: [1, 9, 8400]
    // 9 = 4 (x, y, w, h) + 5 (sınıf sayısı)
    // 8400 = toplam detection sayısı
    
    try {
      final batch = output[0];
      final numDetections = shape[2]; // 8400
      final numClasses = 5;
      
      // İlk birkaç değeri debug için yazdır
      print('İlk detection raw values:');
      print('x: ${batch[0][0]}, y: ${batch[1][0]}, w: ${batch[2][0]}, h: ${batch[3][0]}');
      print('class confs: ${batch[4][0]}, ${batch[5][0]}, ${batch[6][0]}, ${batch[7][0]}, ${batch[8][0]}');
      
      for (int i = 0; i < numDetections; i++) {
        // Sınıf confidence'larını kontrol et
        double maxConf = 0;
        int maxClassIndex = 0;
        
        for (int c = 0; c < numClasses; c++) {
          double conf = (batch[4 + c][i] is double) ? batch[4 + c][i] : (batch[4 + c][i] as num).toDouble();
          if (conf > maxConf) {
            maxConf = conf;
            maxClassIndex = c;
          }
        }
        
        // Eşik değerini geçenleri ekle
        if (maxConf > confidenceThreshold) {
          double x = (batch[0][i] is double) ? batch[0][i] : (batch[0][i] as num).toDouble();
          double y = (batch[1][i] is double) ? batch[1][i] : (batch[1][i] as num).toDouble();
          double w = (batch[2][i] is double) ? batch[2][i] : (batch[2][i] as num).toDouble();
          double h = (batch[3][i] is double) ? batch[3][i] : (batch[3][i] as num).toDouble();
          
          detections.add(DetectionResult(
            className: _labels![maxClassIndex],
            confidence: maxConf,
            box: [x, y, w, h],
          ));
        }
      }
      
      print('NMS öncesi tespit: ${detections.length}');
      
      // NMS uygula - aynı nesneyi birden fazla tespit etmeyi önle
      detections = _applyNMS(detections, 0.5);
      
    } catch (e) {
      print('Parse error: $e');
    }
    
    print('Toplam tespit: ${detections.length}');
    return detections;
  }

  // Non-Maximum Suppression
  static List<DetectionResult> _applyNMS(List<DetectionResult> detections, double iouThreshold) {
    if (detections.isEmpty) return detections;
    
    // Confidence'a göre sırala (yüksekten düşüğe)
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    List<DetectionResult> result = [];
    List<bool> suppressed = List.filled(detections.length, false);
    
    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      
      result.add(detections[i]);
      
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        
        // Aynı sınıfsa ve IoU yüksekse bastır
        if (detections[i].className == detections[j].className) {
          double iou = _calculateIoU(detections[i].box, detections[j].box);
          if (iou > iouThreshold) {
            suppressed[j] = true;
          }
        }
      }
    }
    
    return result;
  }

  // IoU (Intersection over Union) hesapla
  static double _calculateIoU(List<double> box1, List<double> box2) {
    // Box format: [x_center, y_center, width, height]
    double x1Min = box1[0] - box1[2] / 2;
    double y1Min = box1[1] - box1[3] / 2;
    double x1Max = box1[0] + box1[2] / 2;
    double y1Max = box1[1] + box1[3] / 2;
    
    double x2Min = box2[0] - box2[2] / 2;
    double y2Min = box2[1] - box2[3] / 2;
    double x2Max = box2[0] + box2[2] / 2;
    double y2Max = box2[1] + box2[3] / 2;
    
    double intersectX = (x1Max < x2Max ? x1Max : x2Max) - (x1Min > x2Min ? x1Min : x2Min);
    double intersectY = (y1Max < y2Max ? y1Max : y2Max) - (y1Min > y2Min ? y1Min : y2Min);
    
    if (intersectX <= 0 || intersectY <= 0) return 0;
    
    double intersection = intersectX * intersectY;
    double area1 = box1[2] * box1[3];
    double area2 = box2[2] * box2[3];
    double union = area1 + area2 - intersection;
    
    return union > 0 ? intersection / union : 0;
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
  }
}
