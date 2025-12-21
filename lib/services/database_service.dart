import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/scan_history.dart';
import '../models/detection_result.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('atik_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scan_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imagePath TEXT NOT NULL,
        detections TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertScan(ScanHistory scan) async {
    final db = await database;
    return await db.insert(
      'scan_history',
      {
        'imagePath': scan.imagePath,
        'detections': jsonEncode(scan.detections.map((d) => d.toJson()).toList()),
        'timestamp': scan.timestamp.toIso8601String(),
      },
    );
  }

  Future<List<ScanHistory>> getAllScans() async {
    final db = await database;
    final result = await db.query('scan_history', orderBy: 'timestamp DESC');

    return result.map((json) {
      return ScanHistory(
        id: json['id'] as int,
        imagePath: json['imagePath'] as String,
        detections: (jsonDecode(json['detections'] as String) as List)
            .map((d) => DetectionResult.fromJson(d))
            .toList(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
    }).toList();
  }

  Future<int> deleteScan(int id) async {
    final db = await database;
    return await db.delete(
      'scan_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllScans() async {
    final allScans = await getAllScans();
    
    // Tüm resim dosyalarını sil
    for (var scan in allScans) {
      try {
        final file = File(scan.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Dosya silinirken hata: $e');
      }
    }
    
    // Veritabanındaki tüm kayıtları sil
    final db = await database;
    return await db.delete('scan_history');
  }

  Future<Map<String, int>> getTotalClassCounts() async {
    final scans = await getAllScans();
    final Map<String, int> totalCounts = {};

    for (var scan in scans) {
      final counts = scan.getClassCounts();
      counts.forEach((className, count) {
        totalCounts[className] = (totalCounts[className] ?? 0) + count;
      });
    }

    return totalCounts;
  }

  Future close() async {
    final db = await database;
    await db.close();
  }
}
