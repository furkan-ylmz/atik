import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../history/history_screen.dart';
import '../scan/scan_options_screen.dart';
import 'widgets/home_menu_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Başlık & Logo Rozeti
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Atık Tespit',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Çevreye duyarlı, akıllı geri dönüşüm',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Menü Kartları
                HomeMenuCard(
                  icon: Icons.camera_alt_rounded,
                  title: 'Tarama Yap',
                  subtitle: 'Kamera veya galeriden atık nesnesi tespit et',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScanOptionsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                HomeMenuCard(
                  icon: Icons.history_rounded,
                  title: 'Tarama Geçmişi',
                  subtitle: 'Önceki tarama sonuçlarını ve istatistikleri gör',
                  color: AppColors.secondary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
                
                const Spacer(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
