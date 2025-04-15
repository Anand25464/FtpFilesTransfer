import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'ftp_connection_event.dart';
import 'ftp_connection_state.dart';
import '../../services/ftp_service.dart';

class FtpConnectionBloc extends Bloc<FtpConnectionEvent, FtpConnectionState> {
  final FtpService _ftpService;
  final Connectivity _connectivity;

  FtpConnectionBloc({
    required FtpService ftpService,
    required Connectivity connectivity,
  })  : _ftpService = ftpService,
        _connectivity = connectivity,
        super(const FtpConnectionState()) {
    on<FtpConnect>(_onFtpConnect);
    on<FtpDisconnect>(_onFtpDisconnect);
    on<FtpCheckConnection>(_onFtpCheckConnection);
    on<FtpRefreshConnection>(_onFtpRefreshConnection);
  }

  Future<void> _onFtpConnect(
      FtpConnect event, Emitter<FtpConnectionState> emit) async {
    emit(state.copyWith(
      status: FtpConnectionStatus.connecting,
      currentServer: event.server,
      clearError: true,
    ));

    try {
      var connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        emit(state.copyWith(
          status: FtpConnectionStatus.failure,
          errorMessage: 'No internet connection',
        ));
        return;
      }

      final success = await _ftpService.connect(
        event.server.host,
        port: event.server.port,
        username: event.server.username,
        password: event.server.password,
      );

      if (success) {
        emit(state.copyWith(
          status: FtpConnectionStatus.connected,
          lastActivity: DateTime.now(),
        ));
      } else {
        emit(state.copyWith(
          status: FtpConnectionStatus.failure,
          errorMessage: 'Failed to connect to FTP server',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FtpConnectionStatus.failure,
        errorMessage: 'Error: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFtpDisconnect(
      FtpDisconnect event, Emitter<FtpConnectionState> emit) async {
    if (state.status != FtpConnectionStatus.connected) {
      return;
    }

    try {
      await _ftpService.disconnect();
      emit(state.copyWith(
        status: FtpConnectionStatus.disconnected,
        lastActivity: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error during disconnection: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFtpCheckConnection(
      FtpCheckConnection event, Emitter<FtpConnectionState> emit) async {
    if (state.status != FtpConnectionStatus.connected) {
      return;
    }

    try {
      final isStillConnected = await _ftpService.isConnected();
      if (!isStillConnected) {
        emit(state.copyWith(
          status: FtpConnectionStatus.disconnected,
          errorMessage: 'Connection lost',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FtpConnectionStatus.failure,
        errorMessage: 'Error checking connection: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFtpRefreshConnection(
      FtpRefreshConnection event, Emitter<FtpConnectionState> emit) async {
    if (state.status != FtpConnectionStatus.disconnected ||
        state.currentServer == null) {
      return;
    }

    add(FtpConnect(state.currentServer!));
  }
}