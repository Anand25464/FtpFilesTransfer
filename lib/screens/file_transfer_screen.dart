import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import '../blocs/file_transfer/file_transfer_bloc.dart';
import '../models/transfer_stats.dart';
import '../widgets/transfer_progress_widget.dart';

class FileTransferScreen extends StatefulWidget {
  final Map<String, dynamic> transferParams;

  const FileTransferScreen({
    Key? key,
    required this.transferParams,
  }) : super(key: key);

  @override
  State<FileTransferScreen> createState() => _FileTransferScreenState();
}

class _FileTransferScreenState extends State<FileTransferScreen> {
  bool _transferStarted = false;

  @override
  void initState() {
    super.initState();
    _startTransfer();
  }

  Future<void> _startTransfer() async {
    if (_transferStarted) return;

    final isUpload = widget.transferParams['isUpload'] as bool;
    
    if (isUpload) {
      final localPath = widget.transferParams['localPath'] as String;
      final remotePath = widget.transferParams['remotePath'] as String;
      
      context.read<FileTransferBloc>().add(
            StartUpload(
              localPath: localPath,
              remotePath: remotePath,
            ),
          );
    } else {
      final remotePath = widget.transferParams['remotePath'] as String;
      final fileName = widget.transferParams['fileName'] as String;
      
      // Get downloads directory for saving files
      final downloadsDir = await _getDownloadsDirectory();
      
      context.read<FileTransferBloc>().add(
            StartDownload(
              remotePath: remotePath,
              localPath: downloadsDir.path,
              fileName: fileName,
            ),
          );
    }
    
    setState(() {
      _transferStarted = true;
    });
  }

  Future<Directory> _getDownloadsDirectory() async {
    Directory? directory;
    
    try {
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        
        // Use documents directory as fallback
        if (!await directory.exists()) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      // Fallback to temporary directory if permissions are not granted
      directory = await getTemporaryDirectory();
    }
    
    return directory;
  }

  @override
  Widget build(BuildContext context) {
    final isUpload = widget.transferParams['isUpload'] as bool;
    final fileName = widget.transferParams['fileName'] as String;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isUpload ? 'Uploading File' : 'Downloading File'),
      ),
      body: BlocConsumer<FileTransferBloc, FileTransferState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
          
          // Show completion message and optionally navigate back
          if (state.activeTransfer == null && _transferStarted) {
            final transfers = state.transfers;
            if (transfers.isNotEmpty) {
              final latestTransfer = transfers.last;
              
              if (latestTransfer.isComplete) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transfer completed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Navigate back after a short delay
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                });
              }
            }
          }
        },
        builder: (context, state) {
          if (state.activeTransfer != null) {
            return _buildActiveTransfer(state.activeTransfer!);
          }
          
          return _buildTransferPreparation(fileName, isUpload);
        },
      ),
    );
  }

  Widget _buildActiveTransfer(TransferStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.type == TransferType.upload
                ? 'Uploading to Server'
                : 'Downloading from Server',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          TransferProgressWidget(
            stats: stats,
            onCancel: stats.isInProgress
                ? () => _cancelTransfer(stats.id)
                : null,
          ),
          if (stats.isComplete) ...[
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Back to Files'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransferPreparation(String fileName, bool isUpload) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Preparing to ${isUpload ? 'upload' : 'download'}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            fileName,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _cancelTransfer(String transferId) {
    context.read<FileTransferBloc>().add(
          CancelTransfer(transferId),
        );
  }
}