import 'waste_category.dart';

class DetectionResultModel {
  final String className;
  final double confidence;
  final List<double> box; // [x_center, y_center, width, height] (0.0 - 1.0 normalize)

  const DetectionResultModel({
    required this.className,
    required this.confidence,
    required this.box,
  });

  WasteCategoryType get category => WasteCategoryType.fromString(className);

  String get formattedConfidence => '${(confidence * 100).toStringAsFixed(1)}%';

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'confidence': confidence,
      'box': box,
    };
  }

  factory DetectionResultModel.fromJson(Map<String, dynamic> json) {
    return DetectionResultModel(
      className: json['className'] as String? ?? 'Bilinmeyen',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      box: (json['box'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [0.0, 0.0, 0.0, 0.0],
    );
  }

  @override
  String toString() => 'DetectionResultModel(class: $className, conf: $confidence, box: $box)';
}
