import 'detection_result_model.dart';

class ScanHistoryModel {
  final int? id;
  final String imagePath;
  final List<DetectionResultModel> detections;
  final DateTime timestamp;

  const ScanHistoryModel({
    this.id,
    required this.imagePath,
    required this.detections,
    required this.timestamp,
  });

  /// Sınıf bazlı nesne sayısını hesaplar
  Map<String, int> getClassCounts() {
    final Map<String, int> counts = {};
    for (final detection in detections) {
      counts[detection.className] = (counts[detection.className] ?? 0) + 1;
    }
    return counts;
  }

  /// Toplam tespit sayısı
  int get totalDetectionCount => detections.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'detections': detections.map((d) => d.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ScanHistoryModel.fromJson(Map<String, dynamic> json) {
    final detectionsRaw = json['detections'];
    List<DetectionResultModel> parsedDetections = [];
    if (detectionsRaw is List) {
      parsedDetections = detectionsRaw
          .map((d) => DetectionResultModel.fromJson(d as Map<String, dynamic>))
          .toList();
    }

    return ScanHistoryModel(
      id: json['id'] as int?,
      imagePath: json['imagePath'] as String? ?? '',
      detections: parsedDetections,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ScanHistoryModel copyWith({
    int? id,
    String? imagePath,
    List<DetectionResultModel>? detections,
    DateTime? timestamp,
  }) {
    return ScanHistoryModel(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      detections: detections ?? this.detections,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
