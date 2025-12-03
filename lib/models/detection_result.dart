class DetectionResult {
  final String className;
  final double confidence;
  final List<double> box; // [x, y, width, height]

  DetectionResult({
    required this.className,
    required this.confidence,
    required this.box,
  });

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'confidence': confidence,
      'box': box,
    };
  }

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      className: json['className'],
      confidence: json['confidence'],
      box: List<double>.from(json['box']),
    );
  }
}
