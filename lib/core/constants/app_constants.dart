class AppConstants {
  AppConstants._();

  // Model & Detection Ayarları
  static const int modelInputSize = 640;
  static const double defaultConfidenceThreshold = 0.65;
  static const double defaultIouThreshold = 0.45;

  // Veritabanı ve Depolama Ayarları
  static const String databaseName = 'atik_history.db';
  static const int databaseVersion = 1;
  static const String scanHistoryTable = 'scan_history';
  static const String scansDirectoryName = 'scans';

  // Animasyon ve Süreler
  static const Duration splashDuration = Duration(milliseconds: 2500);
  static const Duration animationDurationFast = Duration(milliseconds: 300);
  static const Duration animationDurationNormal = Duration(milliseconds: 500);

  // UI Boyutları
  static const double defaultBorderRadius = 16.0;
  static const double largeBorderRadius = 24.0;
  static const double cardElevation = 4.0;
}
