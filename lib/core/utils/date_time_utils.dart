class DateTimeUtils {
  DateTimeUtils._();

  /// Tarihi kullanıcı dostu metne dönüştürür (Bugün, Dün veya GG/AA/YYYY)
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scanDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(scanDate).inDays;

    if (difference == 0) {
      return 'Bugün';
    } else if (difference == 1) {
      return 'Dün';
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day.$month.${date.year}';
    }
  }

  /// Saati SS:DD formatında döndürür
  static String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Tam tarih ve saat metni
  static String formatFullDateTime(DateTime date) {
    return '${formatDate(date)} ${formatTime(date)}';
  }
}
