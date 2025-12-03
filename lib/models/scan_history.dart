import 'detection_result.dart';

class ScanHistory {
  final int? id;
  final String imagePath;
  final List<DetectionResult> detections;
  final DateTime timestamp;

  ScanHistory({
    this.id,
    required this.imagePath,
    required this.detections,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'detections': detections.map((d) => d.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ScanHistory.fromJson(Map<String, dynamic> json) {
    return ScanHistory(
      id: json['id'],
      imagePath: json['imagePath'],
      detections: (json['detections'] as List)
          .map((d) => DetectionResult.fromJson(d))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  // Sınıf bazlı nesne sayısını hesapla
  Map<String, int> getClassCounts() {
    final Map<String, int> counts = {};
    for (var detection in detections) {
      counts[detection.className] = (counts[detection.className] ?? 0) + 1;
    }
    return counts;
  }
}
