import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/ftp_connection/ftp_connection_bloc.dart';
import '../blocs/ftp_connection/ftp_connection_state.dart';

class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FtpConnectionBloc, FtpConnectionState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(state.status),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(state.status),
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(state.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(FtpConnectionStatus status) {
    switch (status) {
      case FtpConnectionStatus.connected:
        return Colors.green;
      case FtpConnectionStatus.connecting:
        return Colors.orange;
      case FtpConnectionStatus.failure:
        return Colors.red;
      case FtpConnectionStatus.disconnected:
        return Colors.grey;
      case FtpConnectionStatus.initial:
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(FtpConnectionStatus status) {
    switch (status) {
      case FtpConnectionStatus.connected:
        return Icons.link;
      case FtpConnectionStatus.connecting:
        return Icons.hourglass_top;
      case FtpConnectionStatus.failure:
        return Icons.error_outline;
      case FtpConnectionStatus.disconnected:
        return Icons.link_off;
      case FtpConnectionStatus.initial:
      default:
        return Icons.link_off;
    }
  }

  String _getStatusText(FtpConnectionStatus status) {
    switch (status) {
      case FtpConnectionStatus.connected:
        return 'Connected';
      case FtpConnectionStatus.connecting:
        return 'Connecting...';
      case FtpConnectionStatus.failure:
        return 'Connection Failed';
      case FtpConnectionStatus.disconnected:
        return 'Disconnected';
      case FtpConnectionStatus.initial:
      default:
        return 'Not Connected';
    }
  }
}