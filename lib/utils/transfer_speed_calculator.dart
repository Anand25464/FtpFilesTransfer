import 'package:intl/intl.dart';
import 'file_size_formatter.dart';

class TransferSpeedCalculator {
  // Format transfer speed in bytes per second
  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 B/s';
    return '${FileSizeFormatter.formatBytes(bytesPerSecond.round())}/s';
  }

  // Format remaining time based on seconds
  static String formatRemainingTime(int? seconds) {
    if (seconds == null || seconds <= 0) return '--:--';
    
    final duration = Duration(seconds: seconds);
    
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${(duration.inHours % 24).toString().padLeft(2, '0')}h';
    }
    
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${(duration.inMinutes % 60).toString().padLeft(2, '0')}m';
    }
    
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${(duration.inSeconds % 60).toString().padLeft(2, '0')}s';
    }
    
    return '${duration.inSeconds}s';
  }

  // Format transfer progress percentage
  static String formatProgress(double progress) {
    final percentage = (progress * 100).round();
    return '$percentage%';
  }

  // Format date and time
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }
}