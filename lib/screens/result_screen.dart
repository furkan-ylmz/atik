import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/scan_history.dart';
import '../models/detection_result.dart';
import '../services/database_service.dart';
import '../services/detection_service.dart';
import '../widgets/detection_painter.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;

  const ResultScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  List<DetectionResult> _detections = [];
  Map<String, int> _classCounts = {};
  ui.Image? _image;
  Size _imageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
    _runDetection();
  }

  Future<void> _loadImage() async {
    final file = File(widget.imagePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    
    if (mounted) {
      setState(() {
        _image = frame.image;
        _imageSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
      });
    }
  }

  Future<void> _runDetection() async {
    try {
      // Gerçek model çalıştır
      final detections = await DetectionService.detectObjects(widget.imagePath);

      if (mounted) {
        setState(() {
          _detections = detections;
          _calculateClassCounts();
          _isLoading = false;
        });

        // Sonuçları veritabanına kaydet
        await _saveToDatabase();
      }
    } catch (e) {
      print('Tespit hatası: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Model hatası: $e')),
        );
      }
    }
  }

  void _calculateClassCounts() {
    _classCounts.clear();
    for (var detection in _detections) {
      _classCounts[detection.className] = (_classCounts[detection.className] ?? 0) + 1;
    }
  }

  Future<void> _saveToDatabase() async {
    final scanHistory = ScanHistory(
      imagePath: widget.imagePath,
      detections: _detections,
      timestamp: DateTime.now(),
    );

    await DatabaseService.instance.insertScan(scanHistory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Fotoğraf bölümü
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // Fotoğraf - ortalanmış
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: _image != null && _detections.isNotEmpty
                        ? Stack(
                            children: [
                              Image.file(
                                File(widget.imagePath),
                                fit: BoxFit.contain,
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: DetectionPainter(
                                    imageFile: File(widget.imagePath),
                                    detections: _detections,
                                    imageSize: _imageSize,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
                
                // Geri butonu
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                
                // Loading overlay
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.7),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 20),
                          Text(
                            'Analiz ediliyor...',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Sonuçlar bölümü
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: _isLoading
                  ? const SizedBox()
                  : _detections.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Atık tespit edilemedi',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            const SizedBox(height: 20),
                            Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.0),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
                                  SizedBox(width: 12),
                                  Text(
                                    'Tespit Sonuçları',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: _detections.length,
                                itemBuilder: (context, index) {
                                  final detection = _detections[index];
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.recycling,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                detection.className,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF2C3E50),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Doğruluk: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '#${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
