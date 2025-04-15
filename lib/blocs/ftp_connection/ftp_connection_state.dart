import 'package:equatable/equatable.dart';
import '../../models/ftp_server.dart';

enum FtpConnectionStatus { initial, connecting, connected, disconnected, failure }

class FtpConnectionState extends Equatable {
  final FtpConnectionStatus status;
  final FtpServer? currentServer;
  final String? errorMessage;
  final DateTime? lastActivity;

  const FtpConnectionState({
    this.status = FtpConnectionStatus.initial,
    this.currentServer,
    this.errorMessage,
    this.lastActivity,
  });

  FtpConnectionState copyWith({
    FtpConnectionStatus? status,
    FtpServer? currentServer,
    String? errorMessage,
    DateTime? lastActivity,
    bool clearError = false,
  }) {
    return FtpConnectionState(
      status: status ?? this.status,
      currentServer: currentServer ?? this.currentServer,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  bool get isConnected => status == FtpConnectionStatus.connected;

  @override
  List<Object?> get props => [status, currentServer, errorMessage, lastActivity];
}