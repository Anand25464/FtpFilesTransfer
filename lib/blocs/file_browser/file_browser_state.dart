import 'package:equatable/equatable.dart';
import '../../models/ftp_file.dart';

enum FileBrowserStatus {
  initial,
  loading,
  loaded,
  error,
}

class FileBrowserState extends Equatable {
  final FileBrowserStatus status;
  final List<FtpFile> files;
  final String currentPath;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final List<String> navigationHistory;

  const FileBrowserState({
    this.status = FileBrowserStatus.initial,
    this.files = const [],
    this.currentPath = '/',
    this.errorMessage,
    this.lastUpdated,
    this.navigationHistory = const ['/'],
  });

  FileBrowserState copyWith({
    FileBrowserStatus? status,
    List<FtpFile>? files,
    String? currentPath,
    String? errorMessage,
    DateTime? lastUpdated,
    List<String>? navigationHistory,
    bool clearError = false,
  }) {
    return FileBrowserState(
      status: status ?? this.status,
      files: files ?? this.files,
      currentPath: currentPath ?? this.currentPath,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      navigationHistory: navigationHistory ?? this.navigationHistory,
    );
  }

  bool get canNavigateUp => currentPath != '/';

  @override
  List<Object?> get props => [
    status, files, currentPath, errorMessage, lastUpdated, navigationHistory
  ];
}