import 'dart:math' as math;

class FileSizeFormatter {
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var i = (bytes > 0) ? (math.log(bytes) / math.log(1024)).floor() : 0;
    
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}