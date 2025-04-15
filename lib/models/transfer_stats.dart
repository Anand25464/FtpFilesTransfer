import 'package:equatable/equatable.dart';

enum TransferType { upload, download }
enum TransferStatus { queued, inProgress, completed, failed, cancelled }

class TransferStats extends Equatable {
  final String id;
  final String fileName;
  final String localPath;
  final String remotePath;
  final int fileSize;
  final int bytesTransferred;
  final TransferType type;
  final TransferStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final String? errorMessage;
  final double currentSpeed; // in bytes per second

  const TransferStats({
    required this.id,
    required this.fileName,
    required this.localPath,
    required this.remotePath,
    required this.fileSize,
    this.bytesTransferred = 0,
    required this.type,
    this.status = TransferStatus.queued,
    required this.startTime,
    this.endTime,
    this.errorMessage,
    this.currentSpeed = 0,
  });

  TransferStats copyWith({
    String? id,
    String? fileName,
    String? localPath,
    String? remotePath,
    int? fileSize,
    int? bytesTransferred,
    TransferType? type,
    TransferStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    String? errorMessage,
    double? currentSpeed,
    bool clearError = false,
  }) {
    return TransferStats(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      remotePath: remotePath ?? this.remotePath,
      fileSize: fileSize ?? this.fileSize,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentSpeed: currentSpeed ?? this.currentSpeed,
    );
  }

  double get progress {
    if (fileSize <= 0) return 0;
    return bytesTransferred / fileSize;
  }

  bool get isComplete => status == TransferStatus.completed;
  bool get isInProgress => status == TransferStatus.inProgress;
  bool get isFailed => status == TransferStatus.failed;

  int? get timeRemainingSeconds {
    if (isComplete || bytesTransferred <= 0 || currentSpeed <= 0) return null;
    
    int remainingBytes = fileSize - bytesTransferred;
    return (remainingBytes / currentSpeed).round();
  }

  @override
  List<Object?> get props => [
    id, fileName, localPath, remotePath, fileSize, bytesTransferred, 
    type, status, startTime, endTime, errorMessage, currentSpeed
  ];
}