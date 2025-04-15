import 'package:flutter/material.dart';
import '../models/ftp_file.dart';
import '../utils/file_size_formatter.dart';
import 'package:intl/intl.dart';

class FileListItem extends StatelessWidget {
  final FtpFile file;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const FileListItem({
    Key? key,
    required this.file,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: _buildIcon(),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        _buildSubtitle(),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
      trailing: file.isDirectory
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : Text(
              FileSizeFormatter.formatBytes(file.size),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget _buildIcon() {
    if (file.isDirectory) {
      return const Icon(Icons.folder, color: Colors.amber);
    } else {
      return _getFileIcon();
    }
  }

  Widget _getFileIcon() {
    final extension = file.name.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return const Icon(Icons.image, color: Colors.blue);
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return const Icon(Icons.movie, color: Colors.red);
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
        return const Icon(Icons.music_note, color: Colors.purple);
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'doc':
      case 'docx':
        return const Icon(Icons.description, color: Colors.blue);
      case 'xls':
      case 'xlsx':
        return const Icon(Icons.table_chart, color: Colors.green);
      case 'ppt':
      case 'pptx':
        return const Icon(Icons.slideshow, color: Colors.orange);
      case 'txt':
        return const Icon(Icons.article, color: Colors.blueGrey);
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return const Icon(Icons.archive, color: Colors.brown);
      default:
        return const Icon(Icons.insert_drive_file, color: Colors.blueGrey);
    }
  }

  String _buildSubtitle() {
    final buffer = StringBuffer();
    
    if (file.modifiedDate != null) {
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
      buffer.write(dateFormat.format(file.modifiedDate!));
    }
    
    if (file.permissions != null && file.permissions!.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.write(' • ');
      }
      buffer.write(file.permissions);
    }
    
    return buffer.toString();
  }
}