import 'package:bloc/bloc.dart';
import 'package:path/path.dart' as path;
import 'file_browser_event.dart';
import 'file_browser_state.dart';
import '../../services/ftp_service.dart';

class FileBrowserBloc extends Bloc<FileBrowserEvent, FileBrowserState> {
  final FtpService _ftpService;

  FileBrowserBloc({required FtpService ftpService})
      : _ftpService = ftpService,
        super(const FileBrowserState()) {
    on<LoadDirectory>(_onLoadDirectory);
    on<CreateDirectory>(_onCreateDirectory);
    on<DeleteFile>(_onDeleteFile);
    on<NavigateUp>(_onNavigateUp);
    on<RefreshCurrentDirectory>(_onRefreshCurrentDirectory);
  }

  Future<void> _onLoadDirectory(
      LoadDirectory event, Emitter<FileBrowserState> emit) async {
    emit(state.copyWith(
      status: FileBrowserStatus.loading,
      currentPath: event.path,
      clearError: true,
    ));

    try {
      final isConnected = await _ftpService.isConnected();
      if (!isConnected) {
        emit(state.copyWith(
          status: FileBrowserStatus.error,
          errorMessage: 'Not connected to FTP server',
        ));
        return;
      }

      final files = await _ftpService.listDirectory(event.path);
      
      // Update navigation history
      final List<String> history = List.from(state.navigationHistory);
      if (history.isEmpty || history.last != event.path) {
        history.add(event.path);
      }
      
      emit(state.copyWith(
        status: FileBrowserStatus.loaded,
        files: files,
        lastUpdated: DateTime.now(),
        navigationHistory: history,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FileBrowserStatus.error,
        errorMessage: 'Error loading directory: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCreateDirectory(
      CreateDirectory event, Emitter<FileBrowserState> emit) async {
    emit(state.copyWith(
      status: FileBrowserStatus.loading,
      clearError: true,
    ));

    try {
      final isConnected = await _ftpService.isConnected();
      if (!isConnected) {
        emit(state.copyWith(
          status: FileBrowserStatus.error,
          errorMessage: 'Not connected to FTP server',
        ));
        return;
      }

      final newPath = path.join(event.currentPath, event.name);
      final success = await _ftpService.createDirectory(newPath);

      if (success) {
        add(LoadDirectory(event.currentPath));
      } else {
        emit(state.copyWith(
          status: FileBrowserStatus.error,
          errorMessage: 'Failed to create directory',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FileBrowserStatus.error,
        errorMessage: 'Error creating directory: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteFile(
      DeleteFile event, Emitter<FileBrowserState> emit) async {
    emit(state.copyWith(
      status: FileBrowserStatus.loading,
      clearError: true,
    ));

    try {
      final isConnected = await _ftpService.isConnected();
      if (!isConnected) {
        emit(state.copyWith(
          status: FileBrowserStatus.error,
          errorMessage: 'Not connected to FTP server',
        ));
        return;
      }

      final filePath = event.file.fullPath;
      bool success;
      
      if (event.file.isDirectory) {
        success = await _ftpService.deleteDirectory(filePath);
      } else {
        success = await _ftpService.deleteFile(filePath);
      }

      if (success) {
        add(LoadDirectory(state.currentPath));
      } else {
        emit(state.copyWith(
          status: FileBrowserStatus.error,
          errorMessage: 'Failed to delete ${event.file.isDirectory ? 'directory' : 'file'}',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FileBrowserStatus.error,
        errorMessage: 'Error deleting file: ${e.toString()}',
      ));
    }
  }

  Future<void> _onNavigateUp(
      NavigateUp event, Emitter<FileBrowserState> emit) async {
    if (event.currentPath == '/') {
      // Already at root
      return;
    }

    final parentPath = path.dirname(event.currentPath);
    add(LoadDirectory(parentPath));
  }

  Future<void> _onRefreshCurrentDirectory(
      RefreshCurrentDirectory event, Emitter<FileBrowserState> emit) async {
    add(LoadDirectory(state.currentPath));
  }
}