import 'dart:async';
import 'dart:io';
import 'package:ftpconnect/ftpconnect.dart' as ftp;
import '../models/ftp_file.dart';
import '../models/transfer_stats.dart';

class FtpService {
  ftp.FTPConnect? _ftpConnect;
  bool _isConnected = false;
  bool _isConnecting = false;
  final Map<String, StreamController<TransferStats>> _transferStreams = {};
  // Active transfers list
  List<TransferStats> _activeTransfersList = [];
  List<TransferStats> get activeTransfers => _activeTransfersList;
  bool get isConnecting => _isConnecting;

  // Remove a transfer from the active list
  void removeTransfer(String transferId) {
    _transferStreams.remove(transferId);
  }
  // Connect to FTP server
  Future<bool> connect(
    String host, {
    int port = 21,
    String username = 'anonymous',
    String password = '',
    bool debug = true,
    bool securityType = false,
  }) async {
    _isConnecting=true;
    try {
      _ftpConnect = ftp.FTPConnect(
        host,
        port: port,
        user: username,
        pass: password,
        showLog: debug,
        securityType: ftp.SecurityType.FTP,
        timeout: 30,
      );
      
      await _ftpConnect!.connect();
      _isConnected = true;
      _isConnecting = false;
      return true;
    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      print('FTP Connection error: $e');
      return false;
    }
  }

  // Disconnect from FTP server
  Future<void> disconnect() async {
    try {
      if (_ftpConnect != null) {
        await _ftpConnect!.disconnect();
      }
      _isConnected = false;
    } catch (e) {
      print('FTP Disconnection error: $e');
      rethrow;
    }
  }

  // Check if connected to FTP server
  bool isConnected() {
    if (_ftpConnect == null) return false;
    return _isConnected;
  }

  // List directory contents
  Future<List<FtpFile>> listDirectory(String path) async {
    if (_ftpConnect == null || !_isConnected) {
      // throw Exception('Not connected to FTP server');
    }

    try {
      // First change to the specified directory
      await _ftpConnect!.changeDirectory(path);
      // Then list the contents
      final result = await _ftpConnect!.listDirectoryContent();
      return result.map((ftpEntry) {
        final isDirectory = ftpEntry.type == "d";
        
        return FtpFile(
          name: ftpEntry.name,
          path: path,
          size: ftpEntry.size ?? 0,
          modifiedDate: ftpEntry.modifyTime,
          type: isDirectory 
              ? FtpFileType.directory 
              : (ftpEntry.type == "l" ? FtpFileType.link : FtpFileType.file),
          permissions: ftpEntry.permission,
        );
      }).toList();
    } catch (e) {
      print('Error listing directory: $e');
      rethrow;
    }
  }

  // Download a file
  Stream<TransferStats> downloadFile(
    String remotePath,
    String localPath,
    String fileName,
  ) {
    final transferId = DateTime.now().millisecondsSinceEpoch.toString();
    final controller = StreamController<TransferStats>();
    _transferStreams[transferId] = controller;

    if (_ftpConnect == null || !_isConnected) {
      controller.addError(Exception('Not connected to FTP server'));
      controller.close();
      return controller.stream;
    }

    // Initial stats object
    final stats = TransferStats(
      id: transferId,
      fileName: fileName,
      localPath: localPath,
      remotePath: remotePath,
      fileSize: 0, // Will be updated once we get the file info
      type: TransferType.download,
      startTime: DateTime.now(),
    );

    controller.add(stats);

    // Start download process
    _startDownload(remotePath, localPath, fileName, stats, controller);

    return controller.stream;
  }

  // Upload a file
  Stream<TransferStats> uploadFile(
    String localPath,
    String remotePath,
  ) {
    final transferId = DateTime.now().millisecondsSinceEpoch.toString();
    final controller = StreamController<TransferStats>();
    _transferStreams[transferId] = controller;

    if (_ftpConnect == null || !_isConnected) {
      controller.addError(Exception('Not connected to FTP server'));
      controller.close();
      return controller.stream;
    }

    final file = File(localPath);
    final fileName = file.path.split('/').last;

    // Initial stats object
    final stats = TransferStats(
      id: transferId,
      fileName: fileName,
      localPath: localPath,
      remotePath: remotePath,
      fileSize: file.lengthSync(),
      type: TransferType.upload,
      startTime: DateTime.now(),
    );

    controller.add(stats);

    // Start upload process
    _startUpload(localPath, remotePath, stats, controller);

    return controller.stream;
  }

  // Cancel transfer
  Future<void> cancelTransfer(String transferId) async {
    if (_transferStreams.containsKey(transferId)) {
      final controller = _transferStreams[transferId]!;
      
      // Add cancelled status to the stream
      controller.add(
        TransferStats(
          id: transferId,
          fileName: '', // This will be updated in the next emit with the correct values
          localPath: '',
          remotePath: '',
          fileSize: 0,
          status: TransferStatus.cancelled,
          type: TransferType.download, // Default value, will be overwritten
          startTime: DateTime.now(),
        ),
      );
      
      // Close the stream
      await controller.close();
      _transferStreams.remove(transferId);
    }
  }

  // Helper method to handle file download
  Future<void> _startDownload(
    String remotePath,
    String localPath,
    String fileName,
    TransferStats initialStats,
    StreamController<TransferStats> controller,
  ) async {
    try {
      // Get file size
      final fileSize = await _ftpConnect!.sizeFile(remotePath);
      
      var stats = initialStats.copyWith(
        fileSize: fileSize,
        status: TransferStatus.inProgress,
      );
      controller.add(stats);

      // Create local directory if it doesn't exist
      final directory = Directory(localPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final fullLocalPath = '$localPath/$fileName';
      
      // Start download with progress tracking
      final stopwatch = Stopwatch()..start();
      int lastBytesTransferred = 0;
      double lastSpeed = 0;
      
      await _ftpConnect!.downloadFile(
        remotePath,
        File(fullLocalPath),
        onProgress: (progressValue, transferredBytes, totalBytes) {
          final bytesTransferred = transferredBytes;
          final currentTime = stopwatch.elapsedMilliseconds;
          
          // Calculate speed (bytes per second)
          if (currentTime > 500) { // Update speed every 500ms
            final bytesPerMs = (bytesTransferred - lastBytesTransferred) / currentTime;
            lastSpeed = bytesPerMs * 1000; // Convert to bytes per second
            lastBytesTransferred = bytesTransferred;
            stopwatch.reset();
            stopwatch.start();
          }
          
          stats = stats.copyWith(
            bytesTransferred: bytesTransferred,
            currentSpeed: lastSpeed,
          );
          
          controller.add(stats);
        },
      );

      // Final status update
      stats = stats.copyWith(
        bytesTransferred: fileSize,
        status: TransferStatus.completed,
        endTime: DateTime.now(),
      );
      controller.add(stats);
    } catch (e) {
      final stats = initialStats.copyWith(
        status: TransferStatus.failed,
        errorMessage: e.toString(),
        endTime: DateTime.now(),
      );
      controller.add(stats);
    } finally {
      // Close the stream
      await Future.delayed(const Duration(seconds: 1)); // Give time for final updates
      await controller.close();
      _transferStreams.remove(initialStats.id);
    }
  }

  // Helper method to handle file upload
  Future<void> _startUpload(
    String localPath,
    String remotePath,
    TransferStats initialStats,
    StreamController<TransferStats> controller,
  ) async {
    try {
      final file = File(localPath);
      final fileSize = file.lengthSync();
      
      var stats = initialStats.copyWith(
        status: TransferStatus.inProgress,
      );
      controller.add(stats);

      // Start upload with progress tracking
      final stopwatch = Stopwatch()..start();
      int lastBytesTransferred = 0;
      double lastSpeed = 0;
      
      await _ftpConnect!.uploadFile(
        file,
        sRemoteName: remotePath,
        onProgress: (progressValue, transferredBytes, totalBytes) {
          final bytesTransferred = transferredBytes;
          final currentTime = stopwatch.elapsedMilliseconds;
          
          // Calculate speed (bytes per second)
          if (currentTime > 500) { // Update speed every 500ms
            final bytesPerMs = (bytesTransferred - lastBytesTransferred) / currentTime;
            lastSpeed = bytesPerMs * 1000; // Convert to bytes per second
            lastBytesTransferred = bytesTransferred;
            stopwatch.reset();
            stopwatch.start();
          }
          
          stats = stats.copyWith(
            bytesTransferred: bytesTransferred,
            currentSpeed: lastSpeed,
          );
          
          controller.add(stats);
        },
      );

      // Final status update
      stats = stats.copyWith(
        bytesTransferred: fileSize,
        status: TransferStatus.completed,
        endTime: DateTime.now(),
      );
      controller.add(stats);
    } catch (e) {
      final stats = initialStats.copyWith(
        status: TransferStatus.failed,
        errorMessage: e.toString(),
        endTime: DateTime.now(),
      );
      controller.add(stats);
    } finally {
      // Close the stream
      await Future.delayed(const Duration(seconds: 5)); // Give time for final updates
      await controller.close();
      _transferStreams.remove(initialStats.id);
    }
  }

  // Create directory
  Future<bool> createDirectory(String path) async {
    if (_ftpConnect == null || !_isConnected) {
      throw Exception('Not connected to FTP server');
    }

    try {
      await _ftpConnect!.makeDirectory(path);
      return true;
    } catch (e) {
      print('Error creating directory: $e');
      return false;
    }
  }

  // Delete file
  Future<bool> deleteFile(String path) async {
    if (_ftpConnect == null || !_isConnected) {
      throw Exception('Not connected to FTP server');
    }

    try {
      await _ftpConnect!.deleteFile(path);
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Delete directory
  Future<bool> deleteDirectory(String path) async {
    if (_ftpConnect == null || !_isConnected) {
      throw Exception('Not connected to FTP server');
    }

    try {
      await _ftpConnect!.deleteDirectory(path);
      return true;
    } catch (e) {
      print('Error deleting directory: $e');
      return false;
    }
  }

  // Change directory
  Future<bool> changeDirectory(String path) async {
    if (_ftpConnect == null || !_isConnected) {
      throw Exception('Not connected to FTP server');
    }

    try {
      await _ftpConnect!.changeDirectory(path);
      return true;
    } catch (e) {
      print('Error changing directory: $e');
      return false;
    }
  }

  // Get current directory
  Future<String> currentDirectory() async {
    if (_ftpConnect == null || !_isConnected) {
      throw Exception('Not connected to FTP server');
    }

    try {
      return await _ftpConnect!.currentDirectory();
    } catch (e) {
      print('Error getting current directory: $e');
      rethrow;
    }
  }
}