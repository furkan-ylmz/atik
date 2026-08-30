import 'dart:io';
import '../../core/utils/app_logger.dart';
import '../datasources/local_database_datasource.dart';
import '../models/scan_history_model.dart';

class HistoryRepository {
  final LocalDatabaseDatasource _dbDatasource;

  HistoryRepository({LocalDatabaseDatasource? dbDatasource})
      : _dbDatasource = dbDatasource ?? LocalDatabaseDatasource.instance;

  /// Yeni bir taramayı veritabanına ekler ve ID'sini döner
  Future<int> saveScan(ScanHistoryModel scan) async {
    return await _dbDatasource.insertScan(scan);
  }

  /// Tüm geçmiş taramaları getirir
  Future<List<ScanHistoryModel>> getAllScans() async {
    return await _dbDatasource.getAllScans();
  }

  /// Tek bir tarama kaydını ve bağlı resim dosyasını siler
  Future<bool> deleteScan(int id, String imagePath) async {
    try {
      // 1. Veritabanından sil
      final rowsAffected = await _dbDatasource.deleteScan(id);

      // 2. Fiziksel resim dosyasını sil
      await _deletePhysicalFile(imagePath);

      return rowsAffected > 0;
    } catch (e, stack) {
      AppLogger.error('Tarama ve dosya silinirken hata', e, stack, 'HistoryRepository');
      return false;
    }
  }

  /// Tüm tarama kayıtlarını ve bağlı tüm resimleri temizler
  Future<int> clearAllHistory() async {
    try {
      final allScans = await _dbDatasource.getAllScans();

      // Tüm dosyaları sil
      for (final scan in allScans) {
        await _deletePhysicalFile(scan.imagePath);
      }

      // Veritabanı tablosunu temizle
      return await _dbDatasource.deleteAllScans();
    } catch (e, stack) {
      AppLogger.error('Tüm geçmiş silinirken hata', e, stack, 'HistoryRepository');
      return 0;
    }
  }

  /// Sınıf bazlı toplam istatistikleri hesaplar
  Future<Map<String, int>> getTotalClassCounts() async {
    final scans = await getAllScans();
    final Map<String, int> totalCounts = {};

    for (final scan in scans) {
      final counts = scan.getClassCounts();
      counts.forEach((className, count) {
        totalCounts[className] = (totalCounts[className] ?? 0) + count;
      });
    }

    return totalCounts;
  }

  Future<void> _deletePhysicalFile(String filePath) async {
    try {
      if (filePath.isEmpty) return;
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.info('Fiziksel dosya silindi: $filePath', 'HistoryRepository');
      }
    } catch (e) {
      AppLogger.error('Fiziksel dosya silinemedi: $filePath', e, null, 'HistoryRepository');
    }
  }
}
