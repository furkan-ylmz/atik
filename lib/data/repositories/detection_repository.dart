import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../datasources/tflite_detector_datasource.dart';
import '../models/detection_result_model.dart';
import '../models/scan_history_model.dart';
import 'history_repository.dart';

class DetectionRepository {
  final TfliteDetectorDatasource _detectorDatasource;
  final HistoryRepository _historyRepository;

  DetectionRepository({
    TfliteDetectorDatasource? detectorDatasource,
    HistoryRepository? historyRepository,
  })  : _detectorDatasource = detectorDatasource ?? TfliteDetectorDatasource.instance,
        _historyRepository = historyRepository ?? HistoryRepository();

  /// Modeli önceden yükler/başlatır
  Future<void> initialize() async {
    await _detectorDatasource.initialize();
  }

  /// Geçici bir resim dosyasını uygulamanın kalıcı belgeler dizinine (scans/) kopyalar
  Future<String> saveImageToLocalStorage(String sourcePath) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String scansDirPath = path.join(appDir.path, AppConstants.scansDirectoryName);
      final Directory scansDir = Directory(scansDirPath);

      if (!await scansDir.exists()) {
        await scansDir.create(recursive: true);
      }

      final String fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String targetPath = path.join(scansDirPath, fileName);

      final File sourceFile = File(sourcePath);
      await sourceFile.copy(targetPath);

      AppLogger.info('Resim kalıcı depolamaya kopyalandı: $targetPath', 'DetectionRepository');
      return targetPath;
    } catch (e, stack) {
      AppLogger.error('Resim kopyalanırken hata', e, stack, 'DetectionRepository');
      rethrow;
    }
  }

  /// Resim üzerinde nesne tespiti yapar ve sonucu veritabanına kaydeder
  Future<ScanHistoryModel> detectAndSave(String imagePath) async {
    // 1. Tespiti çalıştır
    final List<DetectionResultModel> detections = await _detectorDatasource.detectObjects(imagePath);

    // 2. Geçmiş modelini oluştur
    final scan = ScanHistoryModel(
      imagePath: imagePath,
      detections: detections,
      timestamp: DateTime.now(),
    );

    // 3. Veritabanına kaydet
    final savedId = await _historyRepository.saveScan(scan);

    return scan.copyWith(id: savedId);
  }

  /// Sadece tespit koşturur (veritabanına kaydetmeden)
  Future<List<DetectionResultModel>> detectOnly(String imagePath) async {
    return await _detectorDatasource.detectObjects(imagePath);
  }
}
