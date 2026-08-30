import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Ana Tema Renkleri
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color primaryDark = Color(0xFF4B42D9);
  
  static const Color secondary = Color(0xFF4CAF50);
  static const Color secondaryLight = Color(0xFF81C784);
  static const Color secondaryDark = Color(0xFF388E3C);

  // Nötr Renkler
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textMuted = Color(0xFFBDC3C7);
  static const Color border = Color(0xFFE2E8F0);

  // Durum Renkleri
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Atık Sınıfı Renkleri
  static const Color wasteGlass = Color(0xFF27AE60);      // Cam (Yeşil)
  static const Color wasteMetal = Color(0xFF7F8C8D);      // Metal (Gri)
  static const Color wasteOrganic = Color(0xFF8D6E63);    // Organik (Kahverengi)
  static const Color wastePaper = Color(0xFF2980B9);      // Kağıt (Mavi)
  static const Color wastePlastic = Color(0xFFF1C40F);    // Plastik (Sarı)
  static const Color wasteUnknown = Color(0xFF95A5A6);    // Bilinmeyen (Açık Gri)

  /// Sınıf adına göre renk döndürür
  static Color getColorForCategory(String className) {
    final normalized = className.trim().toLowerCase();
    switch (normalized) {
      case 'cam':
      case 'glass':
        return wasteGlass;
      case 'metal':
        return wasteMetal;
      case 'organik':
      case 'organic':
        return wasteOrganic;
      case 'kagit':
      case 'kağıt':
      case 'paper':
        return wastePaper;
      case 'plastik':
      case 'plastic':
        return wastePlastic;
      default:
        return wasteUnknown;
    }
  }
}
