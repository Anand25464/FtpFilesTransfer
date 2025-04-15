import 'package:equatable/equatable.dart';

enum FtpFileType { file, directory, link, unknown }

class FtpFile extends Equatable {
  final String name;
  final String path;
  final int size;
  final DateTime? modifiedDate;
  final FtpFileType type;
  final String? permissions;

  const FtpFile({
    required this.name,
    required this.path,
    required this.size,
    this.modifiedDate,
    required this.type,
    this.permissions,
  });

  bool get isDirectory => type == FtpFileType.directory;
  bool get isFile => type == FtpFileType.file;
  bool get isLink => type == FtpFileType.link;

  String get fullPath {
    if (path.endsWith('/')) {
      return '$path$name';
    } else {
      return '$path/$name';
    }
  }

  @override
  List<Object?> get props => [name, path, size, modifiedDate, type, permissions];
}