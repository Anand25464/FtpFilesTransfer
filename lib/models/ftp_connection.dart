class FtpConnection {
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final bool isAnonymous;
  final bool isPassive;
  final Duration timeout;
  final bool secure;

  FtpConnection({
    required this.name,
    required this.host,
    this.port = 21,
    this.username = 'Anand',
    this.password = '1234',
    this.isAnonymous = false,
    this.isPassive = true,
    this.timeout = const Duration(seconds: 30),
    this.secure = false,
  });

  FtpConnection copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    bool? isAnonymous,
    bool? isPassive,
    Duration? timeout,
    bool? secure,
  }) {
    return FtpConnection(
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isPassive: isPassive ?? this.isPassive,
      timeout: timeout ?? this.timeout,
      secure: secure ?? this.secure,
    );
  }

  // Create from JSON for storage
  factory FtpConnection.fromJson(Map<String, dynamic> json) {
    return FtpConnection(
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int,
      username: json['username'] as String,
      password: json['password'] as String,
      isAnonymous: json['isAnonymous'] as bool,
      isPassive: json['isPassive'] as bool,
      timeout: Duration(seconds: json['timeout'] as int),
      secure: json['secure'] as bool,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'isAnonymous': isAnonymous,
      'isPassive': isPassive,
      'timeout': timeout.inSeconds,
      'secure': secure,
    };
  }

  @override
  String toString() {
    return '$name - $host:$port';
  }
}
