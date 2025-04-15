import 'package:equatable/equatable.dart';
import '../../models/ftp_file.dart';

abstract class FileBrowserEvent extends Equatable {
  const FileBrowserEvent();

  @override
  List<Object?> get props => [];
}

class LoadDirectory extends FileBrowserEvent {
  final String path;

  const LoadDirectory(this.path);

  @override
  List<Object?> get props => [path];
}

class CreateDirectory extends FileBrowserEvent {
  final String name;
  final String currentPath;

  const CreateDirectory({
    required this.name,
    required this.currentPath,
  });

  @override
  List<Object?> get props => [name, currentPath];
}

class DeleteFile extends FileBrowserEvent {
  final FtpFile file;

  const DeleteFile(this.file);

  @override
  List<Object?> get props => [file];
}

class NavigateUp extends FileBrowserEvent {
  final String currentPath;

  const NavigateUp(this.currentPath);

  @override
  List<Object?> get props => [currentPath];
}

class RefreshCurrentDirectory extends FileBrowserEvent {}