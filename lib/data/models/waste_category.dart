import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum WasteCategoryType {
  glass,
  metal,
  organic,
  paper,
  plastic,
  unknown;

  static WasteCategoryType fromString(String name) {
    final normalized = name.trim().toLowerCase();
    switch (normalized) {
      case 'cam':
      case 'glass':
        return WasteCategoryType.glass;
      case 'metal':
        return WasteCategoryType.metal;
      case 'organik':
      case 'organic':
        return WasteCategoryType.organic;
      case 'kagit':
      case 'kağıt':
      case 'paper':
        return WasteCategoryType.paper;
      case 'plastik':
      case 'plastic':
        return WasteCategoryType.plastic;
      default:
        return WasteCategoryType.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case WasteCategoryType.glass:
        return 'Cam';
      case WasteCategoryType.metal:
        return 'Metal';
      case WasteCategoryType.organic:
        return 'Organik';
      case WasteCategoryType.paper:
        return 'Kağıt';
      case WasteCategoryType.plastic:
        return 'Plastik';
      case WasteCategoryType.unknown:
        return 'Bilinmeyen Atık';
    }
  }

  Color get color {
    switch (this) {
      case WasteCategoryType.glass:
        return AppColors.wasteGlass;
      case WasteCategoryType.metal:
        return AppColors.wasteMetal;
      case WasteCategoryType.organic:
        return AppColors.wasteOrganic;
      case WasteCategoryType.paper:
        return AppColors.wastePaper;
      case WasteCategoryType.plastic:
        return AppColors.wastePlastic;
      case WasteCategoryType.unknown:
        return AppColors.wasteUnknown;
    }
  }

  IconData get icon {
    switch (this) {
      case WasteCategoryType.glass:
        return Icons.wine_bar_rounded;
      case WasteCategoryType.metal:
        return Icons.inventory_2_rounded;
      case WasteCategoryType.organic:
        return Icons.eco_rounded;
      case WasteCategoryType.paper:
        return Icons.newspaper_rounded;
      case WasteCategoryType.plastic:
        return Icons.local_drink_rounded;
      case WasteCategoryType.unknown:
        return Icons.delete_outline_rounded;
    }
  }

  String get recyclingTip {
    switch (this) {
      case WasteCategoryType.glass:
        return 'Cam atıkları yeşil/şeffaf cam kumbaralarına atmadan önce çalkalayınız.';
      case WasteCategoryType.metal:
        return 'Metal kutuları sıkıştırarak hacmini küçültüp geri dönüşüm kutusuna atınız.';
      case WasteCategoryType.organic:
        return 'Kompost yapılabilir veya biyolojik atık kutularına atılabilir.';
      case WasteCategoryType.paper:
        return 'Kağıt ve kartonları ıslanmadan ve yağlanmadan kuru olarak ayrıştırınız.';
      case WasteCategoryType.plastic:
        return 'Plastik şişelerin kapaklarını ayrı veya takılı olarak plastik kutusuna atınız.';
      case WasteCategoryType.unknown:
        return 'Atık türünü kontrol edip en uygun geri dönüşüm kutusuna bırakınız.';
    }
  }
}
