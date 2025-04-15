import 'dart:math';

class TransferCalculator {
  // Calculate transfer speed in bytes per second
  static double calculateSpeed(int bytesTransferred, int millisElapsed) {
    if (millisElapsed <= 0) return 0;
    return (bytesTransferred / millisElapsed) * 1000;
  }

  // Calculate estimated remaining time
  static Duration calculateEstimatedTime(int totalBytes, int bytesTransferred, double currentSpeed) {
    if (currentSpeed <= 0 || bytesTransferred >= totalBytes) {
      return Duration.zero;
    }
    
    final remainingBytes = totalBytes - bytesTransferred;
    final remainingSeconds = remainingBytes / max(currentSpeed, 1);
    return Duration(seconds: remainingSeconds.round());
  }

  // Format speed for display
  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(1)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else if (bytesPerSecond < 1024 * 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
    }
  }

  // Format remaining time for display
  static String formatRemainingTime(Duration duration) {
    if (duration.inSeconds < 1) {
      return 'less than a second';
    } else if (duration.inSeconds < 60) {
      return '${duration.inSeconds} seconds';
    } else if (duration.inMinutes < 60) {
      final seconds = duration.inSeconds % 60;
      return '${duration.inMinutes} min${seconds > 0 ? ' $seconds sec' : ''}';
    } else {
      final minutes = duration.inMinutes % 60;
      return '${duration.inHours} hr${minutes > 0 ? ' $minutes min' : ''}';
    }
  }

  // Format progress percentage
  static String formatProgressPercentage(int bytesTransferred, int totalBytes) {
    if (totalBytes <= 0) return '0%';
    final percentage = (bytesTransferred / totalBytes) * 100;
    return '${percentage.toStringAsFixed(1)}%';
  }

  // Calculate moving average for speed
  static double calculateMovingAverageSpeed(List<double> recentSpeeds) {
    if (recentSpeeds.isEmpty) return 0;
    
    final sum = recentSpeeds.reduce((a, b) => a + b);
    return sum / recentSpeeds.length;
  }

  // Format elapsed time
  static String formatElapsedTime(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} sec';
    } else if (duration.inMinutes < 60) {
      final seconds = duration.inSeconds % 60;
      return '${duration.inMinutes} min${seconds > 0 ? ' $seconds sec' : ''}';
    } else {
      final minutes = duration.inMinutes % 60;
      return '${duration.inHours} hr${minutes > 0 ? ' $minutes min' : ''}';
    }
  }
}
