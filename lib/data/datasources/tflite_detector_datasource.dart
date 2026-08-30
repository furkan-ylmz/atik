import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/asset_paths.dart';
import '../../core/utils/app_logger.dart';
import '../models/detection_result_model.dart';

class TfliteDetectorDatasource {
  static final TfliteDetectorDatasource instance = TfliteDetectorDatasource._internal();

  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isInitialized = false;

  TfliteDetectorDatasource._internal();

  bool get isInitialized => _isInitialized && _interpreter != null && _labels != null;
  List<String> get labels => _labels ?? [];

  /// Model ve etiket dosyasını yükler
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('TFLite modeli ve etiketler yükleniyor...', 'TfliteDetectorDatasource');
      
      // Model yükle
      _interpreter = await Interpreter.fromAsset(AssetPaths.tfliteModel);

      // Etiketleri yükle
      final labelsData = await rootBundle.loadString(AssetPaths.labels);
      _labels = labelsData
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      _isInitialized = true;
      AppLogger.info(
        'Model hazır. Giriş tensor: ${_interpreter!.getInputTensors().map((t) => t.shape)}, Sınıflar: $_labels',
        'TfliteDetectorDatasource',
      );
    } catch (e, stack) {
      AppLogger.error('Model başlatma hatası', e, stack, 'TfliteDetectorDatasource');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Verilen resim yolundaki nesneleri tespit eder
  Future<List<DetectionResultModel>> detectObjects(
    String imagePath, {
    double confidenceThreshold = AppConstants.defaultConfidenceThreshold,
    double iouThreshold = AppConstants.defaultIouThreshold,
  }) async {
    if (!_isInitialized || _interpreter == null || _labels == null) {
      await initialize();
    }

    try {
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      // Resmi yükle ve boyutlandır
      final inputData = await _preprocessImage(imagePath);

      // Çıktı buffer'ını oluştur [batch, features, detections] -> [1, 9, 8400]
      final output = List.generate(
        outputShape[0],
        (_) => List.generate(
          outputShape[1],
          (_) => List.filled(outputShape[2], 0.0),
        ),
      );

      // Modeli koştur
      _interpreter!.run(inputData, output);

      // Sonuçları ayrıştır
      return _parseOutput(
        output,
        outputShape,
        confidenceThreshold: confidenceThreshold,
        iouThreshold: iouThreshold,
      );
    } catch (e, stack) {
      AppLogger.error('Nesne tespiti sırasında hata', e, stack, 'TfliteDetectorDatasource');
      return [];
    }
  }

  /// Resmi 640x640 boyutuna getirir ve normalize edilmiş tensor dizisine çevirir
  Future<List<List<List<List<double>>>>> _preprocessImage(String imagePath) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final img.Image? decoded = img.decodeImage(imageBytes);

    if (decoded == null) {
      throw Exception('Resim dosyası çözümlenemedi (decode failed): $imagePath');
    }

    final img.Image resized = img.copyResize(
      decoded,
      width: AppConstants.modelInputSize,
      height: AppConstants.modelInputSize,
    );

    const int size = AppConstants.modelInputSize;
    final List<List<List<double>>> imageTensor = List.generate(
      size,
      (y) => List.generate(
        size,
        (x) {
          final pixel = resized.getPixel(x, y);
          return [
            pixel.r / 255.0,
            pixel.g / 255.0,
            pixel.b / 255.0,
          ];
        },
      ),
    );

    return [imageTensor]; // Shape: [1, 640, 640, 3]
  }

  /// YOLOv8 model çıktısını parse edip NMS uygular
  List<DetectionResultModel> _parseOutput(
    List output,
    List<int> shape, {
    required double confidenceThreshold,
    required double iouThreshold,
  }) {
    final List<DetectionResultModel> detections = [];

    try {
      final batch = output[0] as List;
      final int numFeatures = shape[1]; // 9 (4 box + sınıflar)
      final int numDetections = shape[2]; // 8400
      final int numClasses = _labels?.length ?? (numFeatures - 4);

      for (int i = 0; i < numDetections; i++) {
        double maxConf = 0.0;
        int maxClassIndex = 0;

        // Sınıf skorlarını tara (4. indeksten itibaren)
        for (int c = 0; c < numClasses; c++) {
          final featureIndex = 4 + c;
          if (featureIndex >= numFeatures) break;

          final rawVal = batch[featureIndex][i];
          final double conf = (rawVal is num) ? rawVal.toDouble() : 0.0;

          if (conf > maxConf) {
            maxConf = conf;
            maxClassIndex = c;
          }
        }

        // Eşik değerini geçen tespitleri al
        if (maxConf >= confidenceThreshold) {
          double x = (batch[0][i] is num) ? (batch[0][i] as num).toDouble() : 0.0;
          double y = (batch[1][i] is num) ? (batch[1][i] as num).toDouble() : 0.0;
          double w = (batch[2][i] is num) ? (batch[2][i] as num).toDouble() : 0.0;
          double h = (batch[3][i] is num) ? (batch[3][i] as num).toDouble() : 0.0;

          // Piksel koordinatları ise normalize et (0..1 aralığına çek)
          if (x > 1.0 || w > 1.0 || y > 1.0 || h > 1.0) {
            x = (x / AppConstants.modelInputSize).clamp(0.0, 1.0);
            y = (y / AppConstants.modelInputSize).clamp(0.0, 1.0);
            w = (w / AppConstants.modelInputSize).clamp(0.0, 1.0);
            h = (h / AppConstants.modelInputSize).clamp(0.0, 1.0);
          }

          final labelName = (maxClassIndex < (_labels?.length ?? 0))
              ? _labels![maxClassIndex]
              : 'Bilinmeyen';

          detections.add(
            DetectionResultModel(
              className: labelName,
              confidence: maxConf,
              box: [x, y, w, h],
            ),
          );
        }
      }

      // NMS (Non-Maximum Suppression) ile çakışan kutuları ele
      final filteredDetections = _applyNMS(detections, iouThreshold);
      AppLogger.info(
        'Ham tespit: ${detections.length}, NMS sonrası: ${filteredDetections.length}',
        'TfliteDetectorDatasource',
      );
      return filteredDetections;
    } catch (e, stack) {
      AppLogger.error('Model çıktısı ayrıştırılırken hata', e, stack, 'TfliteDetectorDatasource');
      return [];
    }
  }

  /// Non-Maximum Suppression (NMS)
  List<DetectionResultModel> _applyNMS(
    List<DetectionResultModel> detections,
    double iouThreshold,
  ) {
    if (detections.isEmpty) return detections;

    // Güven skoruna göre yüksekten düşüğe sırala
    final sorted = List<DetectionResultModel>.from(detections)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final List<DetectionResultModel> selected = [];
    final List<bool> suppressed = List.filled(sorted.length, false);

    for (int i = 0; i < sorted.length; i++) {
      if (suppressed[i]) continue;

      selected.add(sorted[i]);

      for (int j = i + 1; j < sorted.length; j++) {
        if (suppressed[j]) continue;

        if (sorted[i].className == sorted[j].className) {
          final iou = _calculateIoU(sorted[i].box, sorted[j].box);
          if (iou > iouThreshold) {
            suppressed[j] = true;
          }
        }
      }
    }

    return selected;
  }

  /// IoU (Kesişim / Birleşim) hesabı
  double _calculateIoU(List<double> box1, List<double> box2) {
    final double x1Min = box1[0] - box1[2] / 2;
    final double y1Min = box1[1] - box1[3] / 2;
    final double x1Max = box1[0] + box1[2] / 2;
    final double y1Max = box1[1] + box1[3] / 2;

    final double x2Min = box2[0] - box2[2] / 2;
    final double y2Min = box2[1] - box2[3] / 2;
    final double x2Max = box2[0] + box2[2] / 2;
    final double y2Max = box2[1] + box2[3] / 2;

    final double intersectX = (x1Max < x2Max ? x1Max : x2Max) - (x1Min > x2Min ? x1Min : x2Min);
    final double intersectY = (y1Max < y2Max ? y1Max : y2Max) - (y1Min > y2Min ? y1Min : y2Min);

    if (intersectX <= 0 || intersectY <= 0) return 0.0;

    final double intersection = intersectX * intersectY;
    final double area1 = box1[2] * box1[3];
    final double area2 = box2[2] * box2[3];
    final double union = area1 + area2 - intersection;

    return union > 0 ? (intersection / union) : 0.0;
  }

  /// Kaynakları serbest bırakır
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
    _isInitialized = false;
    AppLogger.info('TFLite interpreter kapatıldı.', 'TfliteDetectorDatasource');
  }
}
