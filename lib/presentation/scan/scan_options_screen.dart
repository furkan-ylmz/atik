import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/detection_repository.dart';
import '../result/result_screen.dart';
import 'scan_camera_screen.dart';

class ScanOptionsScreen extends StatelessWidget {
  final DetectionRepository _detectionRepository;

  ScanOptionsScreen({
    super.key,
    DetectionRepository? detectionRepository,
  }) : _detectionRepository = detectionRepository ?? DetectionRepository();

  Future<void> _pickImageFromGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile != null && context.mounted) {
        // Kalıcı depolamaya kaydet
        final permanentPath = await _detectionRepository.saveImageToLocalStorage(pickedFile.path);

        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ResultScreen(imagePath: permanentPath),
            ),
          );
        }
      }
    } catch (e, stack) {
      AppLogger.error('Galeriden resim seçilemedi', e, stack, 'ScanOptionsScreen');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf seçilemedi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _openCamera(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ScanCameraScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.08),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Geri Butonu & Başlık
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 28, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tarama Yöntemi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Seçenek Kartları
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildOptionCard(
                      context,
                      icon: Icons.camera_alt_rounded,
                      title: 'Kamera ile Çek',
                      subtitle: 'Canlı kamera vizöründen fotoğraf çek ve tespit et',
                      color: AppColors.primary,
                      onTap: () => _openCamera(context),
                    ),
                    const SizedBox(height: 20),
                    _buildOptionCard(
                      context,
                      icon: Icons.photo_library_rounded,
                      title: 'Galeriden Seç',
                      subtitle: 'Cihazındaki mevcut fotoğraflardan bir atık seç',
                      color: AppColors.secondary,
                      onTap: () => _pickImageFromGallery(context),
                    ),
                  ],
                ),
              ),

              const Spacer(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.12),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
                child: Icon(
                  icon,
                  size: 38,
                  color: color,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
