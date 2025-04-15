import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/ftp_file.dart';

class FileUtils {
  // Get formatted file size
  static String formatFileSize(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  // Format date
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  // Get file icon based on extension
  static String getFileIconName(FtpFile file) {
    if (file.isDirectory) {
      return 'folder';
    }
    
    if (file.name == '..') {
      return 'folder_up';
    }

    final extension = path.extension(file.name).toLowerCase();
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
      case '.webp':
        return 'image';
      case '.mp4':
      case '.avi':
      case '.mov':
      case '.mkv':
      case '.wmv':
        return 'video';
      case '.mp3':
      case '.wav':
      case '.ogg':
      case '.m4a':
      case '.flac':
        return 'audio';
      case '.pdf':
        return 'pdf';
      case '.doc':
      case '.docx':
        return 'document';
      case '.xls':
      case '.xlsx':
        return 'spreadsheet';
      case '.ppt':
      case '.pptx':
        return 'presentation';
      case '.zip':
      case '.rar':
      case '.7z':
      case '.tar':
      case '.gz':
        return 'archive';
      case '.txt':
      case '.md':
      case '.rtf':
        return 'text';
      case '.html':
      case '.htm':
      case '.xml':
      case '.json':
        return 'code';
      case '.exe':
      case '.apk':
      case '.app':
        return 'executable';
      default:
        return 'file';
    }
  }

  // Get file type from extension for filtering
  static String getFileType(String filename) {
    final extension = path.extension(filename).toLowerCase();
    
    // Images
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
      return 'image';
    }
    
    // Videos
    if (['.mp4', '.avi', '.mov', '.mkv', '.wmv'].contains(extension)) {
      return 'video';
    }
    
    // Audio
    if (['.mp3', '.wav', '.ogg', '.m4a', '.flac'].contains(extension)) {
      return 'audio';
    }
    
    // Documents
    if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.md', '.rtf'].contains(extension)) {
      return 'document';
    }
    
    // Archives
    if (['.zip', '.rar', '.7z', '.tar', '.gz'].contains(extension)) {
      return 'archive';
    }
    
    return 'other';
  }

  // Get local downloads directory
  static Future<String> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      return directory?.path ?? (await getApplicationDocumentsDirectory()).path;
    } else if (Platform.isIOS) {
      return (await getApplicationDocumentsDirectory()).path;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }
  
  // Get a safe filename (remove invalid characters)
  static String getSafeFilename(String filename) {
    return filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
  
  // Generate a unique filename if the file already exists
  static Future<String> getUniqueFilePath(String directory, String filename) async {
    final safeFilename = getSafeFilename(filename);
    String filePath = path.join(directory, safeFilename);
    
    if (!await File(filePath).exists()) {
      return filePath;
    }
    
    // If file exists, add a number suffix
    int counter = 1;
    final extension = path.extension(safeFilename);
    final nameWithoutExtension = path.basenameWithoutExtension(safeFilename);
    
    while (true) {
      final newName = '${nameWithoutExtension}_$counter$extension';
      filePath = path.join(directory, newName);
      
      if (!await File(filePath).exists()) {
        return filePath;
      }
      
      counter++;
    }
  }
  
  // Check if path is valid
  static bool isValidPath(String path) {
    try {
      return path.isNotEmpty && Directory(path).existsSync();
    } catch (e) {
      return false;
    }
  }

  // pow and log functions for size formatting
  static double pow(num x, num exponent) => x.toDouble() * exponent.toDouble();
  static double log(num x) => log10(x) / log10(1024);
  static double log10(num x) => x == 0 ? 0 : _logBase(x, 10);
  static double _logBase(num x, num base) => x == 0 ? 0 : log_(x) / log_(base);
  static double log_(num x) => x.toDouble() <= 0 ? 0 : log(x);
}
