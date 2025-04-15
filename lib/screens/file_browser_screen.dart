import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../blocs/file_browser/file_browser_bloc.dart';
import '../blocs/file_browser/file_browser_event.dart';
import '../blocs/file_browser/file_browser_state.dart';
import '../blocs/ftp_connection/ftp_connection_bloc.dart';
import '../blocs/ftp_connection/ftp_connection_event.dart';
import '../blocs/ftp_connection/ftp_connection_state.dart';
import '../models/ftp_file.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/file_list_item.dart';

class FileBrowserScreen extends StatefulWidget {
  const FileBrowserScreen({Key? key}) : super(key: key);

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger initial directory load
    context.read<FileBrowserBloc>().add(const LoadDirectory('/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Browser'),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: BlocBuilder<FtpConnectionBloc, FtpConnectionState>(
              builder: (context, state) {
                return state.status == FtpConnectionStatus.connected
                    ? const ConnectionStatusWidget()
                    : IconButton(
                        icon: const Icon(Icons.link_off),
                        tooltip: 'Reconnect',
                        onPressed: () => _reconnect(),
                      );
              },
            ),
          ),
        ],
      ),
      body: BlocConsumer<FileBrowserBloc, FileBrowserState>(
        listener: (context, state) {
          if (state.status == FileBrowserStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          // Show loading indicator while loading
          if (state.status == FileBrowserStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Show empty state if no files or error
          if (state.files.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.status == FileBrowserStatus.error
                        ? 'Error loading files'
                        : 'No files in this directory',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    onPressed: () {
                      context.read<FileBrowserBloc>().add(RefreshCurrentDirectory());
                    },
                  ),
                ],
              ),
            );
          }

          // Show file list
          return Column(
            children: [
              // Current path indicator
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      tooltip: 'Go Up',
                      onPressed: state.canNavigateUp
                          ? () {
                              context.read<FileBrowserBloc>().add(
                                    NavigateUp(state.currentPath),
                                  );
                            }
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Path: ${state.currentPath}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              // File list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<FileBrowserBloc>().add(RefreshCurrentDirectory());
                  },
                  child: ListView.separated(
                    itemCount: state.files.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final file = state.files[index];
                      return FileListItem(
                        file: file,
                        onTap: () => _handleFileTap(file),
                        onLongPress: () => _showFileOptions(file),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _createNewFolder,
            heroTag: 'createFolder',
            tooltip: 'Create Folder',
            child: const Icon(Icons.create_new_folder),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _uploadFile,
            heroTag: 'uploadFile',
            tooltip: 'Upload File',
            child: const Icon(Icons.upload_file),
          ),
        ],
      ),
    );
  }

  void _handleFileTap(FtpFile file) {
    if (file.isDirectory) {
      // Navigate to directory
      context.read<FileBrowserBloc>().add(LoadDirectory(file.fullPath));
    } else {
      // Show file options
      _showFileOptions(file);
    }
  }

  void _showFileOptions(FtpFile file) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Download'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadFile(file);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(file);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _createNewFolder() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Folder'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Folder Name',
              prefixIcon: Icon(Icons.folder),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final currentState = context.read<FileBrowserBloc>().state;
                  context.read<FileBrowserBloc>().add(
                        CreateDirectory(
                          name: controller.text,
                          currentPath: currentState.currentPath,
                        ),
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _uploadFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        // We need to navigate to the upload screen
        final currentState = context.read<FileBrowserBloc>().state;
        
        // Navigate to transfer screen with file and remote path information
        Navigator.of(context).pushNamed(
          '/transfer',
          arguments: {
            'localPath': file.path!,
            'remotePath': '${currentState.currentPath}/${file.name}',
            'fileName': file.name,
            'isUpload': true,
          },
        );
      }
    }
  }

  void _downloadFile(FtpFile file) {
    // Navigate to transfer screen with file information
    Navigator.of(context).pushNamed(
      '/transfer',
      arguments: {
        'remotePath': file.fullPath,
        'fileName': file.name,
        'fileSize': file.size,
        'isUpload': false,
      },
    );
  }

  void _confirmDelete(FtpFile file) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete "${file.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<FileBrowserBloc>().add(DeleteFile(file));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _reconnect() {
    final connectionState = context.read<FtpConnectionBloc>().state;
    if (connectionState.currentServer != null) {
      context.read<FtpConnectionBloc>().add(
            FtpConnect(connectionState.currentServer!),
          );
    } else {
      // Navigate back to connection screen if no server details
      Navigator.of(context).pushReplacementNamed('/connection');
    }
  }
}