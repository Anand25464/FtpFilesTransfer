import 'package:equatable/equatable.dart';
import '../../models/ftp_server.dart';

abstract class FtpConnectionEvent extends Equatable {
  const FtpConnectionEvent();

  @override
  List<Object?> get props => [];
}

class FtpConnect extends FtpConnectionEvent {
  final FtpServer server;

  const FtpConnect(this.server);

  @override
  List<Object?> get props => [server];
}

class FtpDisconnect extends FtpConnectionEvent {}

class FtpCheckConnection extends FtpConnectionEvent {}

class FtpRefreshConnection extends FtpConnectionEvent {}