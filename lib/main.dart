import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'data/repositories/detection_repository.dart';
import 'presentation/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sadece dikey (portrait) modu destekle
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Model ve etiketleri arka planda önceden başlat
  try {
    final detectionRepository = DetectionRepository();
    await detectionRepository.initialize();
  } catch (e, stack) {
    AppLogger.error('Uygulama başlangıcında model yüklenemedi', e, stack, 'main');
  }

  runApp(const WasteDetectionApp());
}

class WasteDetectionApp extends StatelessWidget {
  const WasteDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atık Tespit',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
