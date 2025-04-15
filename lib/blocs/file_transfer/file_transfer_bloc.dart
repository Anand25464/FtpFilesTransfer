import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/transfer_stats.dart';
import '../../services/ftp_service.dart';

// Events
abstract class FileTransferEvent extends Equatable {
  const FileTransferEvent();

  @override
  List<Object?> get props => [];
}

class StartUpload extends FileTransferEvent {
  final String localPath;
  final String remotePath;

  const StartUpload({
    required this.localPath,
    required this.remotePath,
  });

  @override
  List<Object?> get props => [localPath, remotePath];
}

class StartDownload extends FileTransferEvent {
  final String remotePath;
  final String localPath;
  final String fileName;

  const StartDownload({
    required this.remotePath,
    required this.localPath,
    required this.fileName,
  });

  @override
  List<Object?> get props => [remotePath, localPath, fileName];
}

class CancelTransfer extends FileTransferEvent {
  final String transferId;

  const CancelTransfer(this.transferId);

  @override
  List<Object?> get props => [transferId];
}

class TransferProgressUpdated extends FileTransferEvent {
  final TransferStats stats;

  const TransferProgressUpdated(this.stats);

  @override
  List<Object?> get props => [stats];
}

// States
class FileTransferState extends Equatable {
  final List<TransferStats> transfers;
  final TransferStats? activeTransfer;
  final String? errorMessage;

  const FileTransferState({
    this.transfers = const [],
    this.activeTransfer,
    this.errorMessage,
  });

  FileTransferState copyWith({
    List<TransferStats>? transfers,
    TransferStats? activeTransfer,
    String? errorMessage,
    bool clearError = false,
    bool clearActiveTransfer = false,
  }) {
    return FileTransferState(
      transfers: transfers ?? this.transfers,
      activeTransfer: clearActiveTransfer ? null : (activeTransfer ?? this.activeTransfer),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [transfers, activeTransfer, errorMessage];
}

// BLoC
class FileTransferBloc extends Bloc<FileTransferEvent, FileTransferState> {
  final FtpService _ftpService;
  StreamSubscription<TransferStats>? _transferSubscription;

  FileTransferBloc({required FtpService ftpService})
      : _ftpService = ftpService,
        super(const FileTransferState()) {
    on<StartUpload>(_onStartUpload);
    on<StartDownload>(_onStartDownload);
    on<CancelTransfer>(_onCancelTransfer);
    on<TransferProgressUpdated>(_onTransferProgressUpdated);
  }

  Future<void> _onStartUpload(
      StartUpload event, Emitter<FileTransferState> emit) async {
    try {
      final stream = _ftpService.uploadFile(
        event.localPath,
        event.remotePath,
      );

      _subscribeToTransferStream(stream);
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to start upload: ${e.toString()}',
      ));
    }
  }

  Future<void> _onStartDownload(
      StartDownload event, Emitter<FileTransferState> emit) async {
    try {
      final stream = _ftpService.downloadFile(
        event.remotePath,
        event.localPath,
        event.fileName,
      );

      _subscribeToTransferStream(stream);
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to start download: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCancelTransfer(
      CancelTransfer event, Emitter<FileTransferState> emit) async {
    try {
      await _ftpService.cancelTransfer(event.transferId);
      
      // We don't need to update state here as the stream will emit a cancelled status
      // which will be handled by the TransferProgressUpdated event
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to cancel transfer: ${e.toString()}',
      ));
    }
  }

  Future<void> _onTransferProgressUpdated(
      TransferProgressUpdated event, Emitter<FileTransferState> emit) async {
    final stats = event.stats;
    
    // Update the active transfer
    emit(state.copyWith(
      activeTransfer: stats,
      clearError: true,
    ));
    
    // If transfer is complete, add it to the list of transfers
    if (stats.status == TransferStatus.completed ||
        stats.status == TransferStatus.failed ||
        stats.status == TransferStatus.cancelled) {
      
      final updatedTransfers = List<TransferStats>.from(state.transfers);
      updatedTransfers.add(stats);
      
      emit(state.copyWith(
        transfers: updatedTransfers,
        clearActiveTransfer: true,
      ));
    }
  }

  void _subscribeToTransferStream(Stream<TransferStats> stream) {
    _transferSubscription?.cancel();
    _transferSubscription = stream.listen(
      (stats) {
        add(TransferProgressUpdated(stats));
      },
      onError: (error) {
        // Handle stream error
        emit(state.copyWith(
          errorMessage: 'Transfer error: ${error.toString()}',
        ));
      },
      onDone: () {
        _transferSubscription = null;
      },
    );
  }

  @override
  Future<void> close() {
    _transferSubscription?.cancel();
    return super.close();
  }
}