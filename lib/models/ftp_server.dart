import 'package:equatable/equatable.dart';

class FtpServer extends Equatable {
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final bool anonymous;
  final bool savePassword;

  const FtpServer({
    required this.name,
    required this.host,
    this.port = 21,
    this.username = '',
    this.password = '',
    this.anonymous = false,
    this.savePassword = false,
  });

  FtpServer copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    bool? anonymous,
    bool? savePassword,
  }) {
    return FtpServer(
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      anonymous: anonymous ?? this.anonymous,
      savePassword: savePassword ?? this.savePassword,
    );
  }

  @override
  List<Object?> get props => [name, host, port, username, password, anonymous, savePassword];
}