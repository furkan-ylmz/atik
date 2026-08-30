import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/scan_history_model.dart';
import '../../data/repositories/history_repository.dart';
import 'widgets/history_item_card.dart';
import 'widgets/history_stats_card.dart';

class HistoryScreen extends StatefulWidget {
  final HistoryRepository? historyRepository;

  const HistoryScreen({
    super.key,
    this.historyRepository,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryRepository _historyRepository;
  List<ScanHistoryModel> _scans = [];
  Map<String, int> _totalCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _historyRepository = widget.historyRepository ?? HistoryRepository();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final scans = await _historyRepository.getAllScans();
      final totalCounts = await _historyRepository.getTotalClassCounts();

      if (mounted) {
        setState(() {
          _scans = scans;
          _totalCounts = totalCounts;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error('Geçmiş yüklenemedi', e, stack, 'HistoryScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteScan(ScanHistoryModel scan) async {
    if (scan.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius)),
        title: const Text('Taramayı Sil'),
        content: const Text('Bu tarama kaydını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _historyRepository.deleteScan(scan.id!, scan.imagePath);
      if (success) {
        await _loadHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarama kaydı silindi.')),
          );
        }
      }
    }
  }

  Future<void> _clearAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius)),
        title: const Text('Tüm Verileri Temizle'),
        content: const Text(
          'Tüm tarama geçmişini ve kayıtlı resimleri silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Tümünü Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final deletedCount = await _historyRepository.clearAllHistory();
      await _loadHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$deletedCount adet tarama kaydı temizlendi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarama Geçmişi'),
        actions: [
          if (_scans.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
              onPressed: _clearAllHistory,
              tooltip: 'Tümünü Temizle',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _scans.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // İstatistik Kartı
                    if (_totalCounts.isNotEmpty)
                      HistoryStatsCard(
                        totalCounts: _totalCounts,
                        totalScans: _scans.length,
                      ),

                    // Geçmiş Listesi
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _scans.length,
                        itemBuilder: (context, index) {
                          final scan = _scans[index];
                          return HistoryItemCard(
                            scan: scan,
                            onDelete: () => _deleteScan(scan),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 72,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Henüz Tarama Yapılmadı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kamera veya galeriden atık fotoğrafları tarayarak geçmişinizi burada görüntüleyebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
