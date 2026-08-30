import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/detection_result_model.dart';
import '../models/scan_history_model.dart';

class LocalDatabaseDatasource {
  static final LocalDatabaseDatasource instance = LocalDatabaseDatasource._internal();
  static Database? _database;

  LocalDatabaseDatasource._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _createDB,
      );
    } catch (e, stack) {
      AppLogger.error('Veritabanı başlatılamadı', e, stack, 'LocalDatabaseDatasource');
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.scanHistoryTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imagePath TEXT NOT NULL,
        detections TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertScan(ScanHistoryModel scan) async {
    try {
      final db = await database;
      final id = await db.insert(
        AppConstants.scanHistoryTable,
        {
          'imagePath': scan.imagePath,
          'detections': jsonEncode(scan.detections.map((d) => d.toJson()).toList()),
          'timestamp': scan.timestamp.toIso8601String(),
        },
      );
      AppLogger.info('Yeni tarama kaydedildi. ID: $id', 'LocalDatabaseDatasource');
      return id;
    } catch (e, stack) {
      AppLogger.error('Tarama kaydedilirken hata', e, stack, 'LocalDatabaseDatasource');
      rethrow;
    }
  }

  Future<List<ScanHistoryModel>> getAllScans() async {
    try {
      final db = await database;
      final results = await db.query(
        AppConstants.scanHistoryTable,
        orderBy: 'timestamp DESC',
      );

      return results.map((row) {
        final detectionsJson = jsonDecode(row['detections'] as String) as List<dynamic>;
        final detections = detectionsJson
            .map((d) => DetectionResultModel.fromJson(d as Map<String, dynamic>))
            .toList();

        return ScanHistoryModel(
          id: row['id'] as int,
          imagePath: row['imagePath'] as String,
          detections: detections,
          timestamp: DateTime.parse(row['timestamp'] as String),
        );
      }).toList();
    } catch (e, stack) {
      AppLogger.error('Geçmiş kayıtları getirilirken hata', e, stack, 'LocalDatabaseDatasource');
      return [];
    }
  }

  Future<int> deleteScan(int id) async {
    try {
      final db = await database;
      return await db.delete(
        AppConstants.scanHistoryTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, stack) {
      AppLogger.error('Tarama silinirken hata. ID: $id', e, stack, 'LocalDatabaseDatasource');
      rethrow;
    }
  }

  Future<int> deleteAllScans() async {
    try {
      final db = await database;
      return await db.delete(AppConstants.scanHistoryTable);
    } catch (e, stack) {
      AppLogger.error('Tüm kayıtlar silinirken hata', e, stack, 'LocalDatabaseDatasource');
      rethrow;
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
