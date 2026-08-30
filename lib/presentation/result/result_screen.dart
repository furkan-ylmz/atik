import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/detection_result_model.dart';
import '../../data/models/scan_history_model.dart';
import '../../data/repositories/detection_repository.dart';
import 'widgets/detection_bounding_box_painter.dart';
import 'widgets/result_item_card.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final ScanHistoryModel? existingScan;
  final DetectionRepository? detectionRepository;

  const ResultScreen({
    super.key,
    required this.imagePath,
    this.existingScan,
    this.detectionRepository,
  });

  /// Geçmişten açıldığında kullanılacak isimlendirilmiş kurucu
  factory ResultScreen.fromHistory({
    Key? key,
    required ScanHistoryModel scan,
  }) {
    return ResultScreen(
      key: key,
      imagePath: scan.imagePath,
      existingScan: scan,
    );
  }

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final DetectionRepository _detectionRepository;
  bool _isLoading = true;
  List<DetectionResultModel> _detections = [];
  Size _imageSize = Size.zero;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _detectionRepository = widget.detectionRepository ?? DetectionRepository();
    _processScreen();
  }

  Future<void> _processScreen() async {
    // 1. Resim boyutlarını oku
    await _loadImageDimensions();

    // 2. Geçmişten geldiyse mevcut verileri kullan (Yeniden ML ve DB çalıştırma!)
    if (widget.existingScan != null) {
      if (mounted) {
        setState(() {
          _detections = widget.existingScan!.detections;
          _isLoading = false;
        });
      }
      return;
    }

    // 3. Yeni tarama ise modeli çalıştır ve veritabanına kaydet
    await _runDetectionAndSave();
  }

  Future<void> _loadImageDimensions() async {
    try {
      final file = File(widget.imagePath);
      if (!await file.exists()) {
        throw Exception('Resim dosyası bulunamadı: ${widget.imagePath}');
      }

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      if (mounted) {
        setState(() {
          _imageSize = Size(
            frame.image.width.toDouble(),
            frame.image.height.toDouble(),
          );
        });
      }
    } catch (e, stack) {
      AppLogger.error('Resim boyutları okunamadı', e, stack, 'ResultScreen');
    }
  }

  Future<void> _runDetectionAndSave() async {
    try {
      final savedScan = await _detectionRepository.detectAndSave(widget.imagePath);

      if (mounted) {
        setState(() {
          _detections = savedScan.detections;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error('Tespit işlemi başarısız', e, stack, 'ResultScreen');
      if (mounted) {
        setState(() {
          _errorMessage = 'Atık tespiti sırasında hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScaffold();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // 1. Fotoğraf ve Bounding Box Bölümü
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.60,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.white70),
                          ),
                        ),
                        if (_detections.isNotEmpty)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: DetectionBoundingBoxPainter(
                                detections: _detections,
                                imageSize: _imageSize,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Geri Butonu
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Sonuçlar ve Bilgi Paneli
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.largeBorderRadius),
                  topRight: Radius.circular(AppConstants.largeBorderRadius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: _errorMessage != null
                  ? _buildErrorState()
                  : _detections.isEmpty
                      ? _buildEmptyState()
                      : _buildResultsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Atık Analiz Ediliyor...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yapay zeka modeli nesneleri sınıflandırıyor',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Bilinmeyen bir hata oluştu',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Atık Tespit Edilemedi',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lütfen nesneyi daha yakından ve iyi aydınlatılmış bir ortamda tekrar çekin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Çekme Tutacağı
        Container(
          width: 44,
          height: 4.5,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 14),

        // Başlık ve Sayı
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Tespit Edilen Atıklar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_detections.length} Nesne',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Sonuç Listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _detections.length,
            itemBuilder: (context, index) {
              return ResultItemCard(
                detection: _detections[index],
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}
