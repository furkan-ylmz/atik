import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../data/models/scan_history_model.dart';
import '../../../data/models/waste_category.dart';
import '../../result/result_screen.dart';

class HistoryItemCard extends StatelessWidget {
  final ScanHistoryModel scan;
  final VoidCallback onDelete;

  const HistoryItemCard({
    super.key,
    required this.scan,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final classCounts = scan.getClassCounts();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultScreen.fromHistory(scan: scan),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Resim Önizleme (Thumbnail)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(scan.imagePath),
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 76,
                        height: 76,
                        color: AppColors.background,
                        child: const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),

                // Tarih ve Kategori Etiketleri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${DateTimeUtils.formatDate(scan.timestamp)} • ${DateTimeUtils.formatTime(scan.timestamp)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (classCounts.isEmpty)
                        const Text(
                          'Atık tespit edilmedi',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: classCounts.entries.map((entry) {
                            final category = WasteCategoryType.fromString(entry.key);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: category.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${category.displayName}: ${entry.value}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: category.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),

                // Silme Butonu
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                  onPressed: onDelete,
                  tooltip: 'Taramayı Sil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
