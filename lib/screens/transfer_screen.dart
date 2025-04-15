import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ftp_service.dart';
import '../models/transfer_stats.dart';
import '../widgets/transfer_progress_widget.dart';
import '../utils/transfer_calculator.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({Key? key}) : super(key: key);

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ftpService = Provider.of<FtpService>(context);
    final activeTransfers = ftpService.activeTransfers;
    
    // Split transfers into active and completed
    final activeTransferItems = activeTransfers.where((e) => e.status == TransferStatus.inProgress)
        .toList();
    
    final completedTransferItems = activeTransfers.where((e) => e.status != TransferStatus.inProgress)
        .toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Transfers'),
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Active (${activeTransferItems.length})',
            ),
            Tab(
              text: 'Completed (${completedTransferItems.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active transfers tab
          activeTransferItems.isEmpty
              ? _buildEmptyState('No active transfers', 'Start a file transfer to see it here')
              : _buildTransferList(activeTransferItems, ftpService, true),
          
          // Completed transfers tab
          completedTransferItems.isEmpty
              ? _buildEmptyState('No completed transfers', 'Completed transfers will appear here')
              : _buildTransferList(completedTransferItems, ftpService, false),
        ],
      ),
      // Clear all completed transfers button (only shown on completed tab)
      floatingActionButton: _tabController.index == 1 && completedTransferItems.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _confirmClearCompleted(ftpService),
              child: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all completed',
            )
          : null,
    );
  }

  // Build transfer list
  Widget _buildTransferList(List<TransferStats> transfers, FtpService ftpService, bool isActive) {
    return ListView.builder(
      itemCount: transfers.length,
      itemBuilder: (context, index) {
        final transferEntry = transfers[index];
        final transferId = transferEntry.id;
        final transfer = transferEntry;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Header with file info
              ListTile(
                leading: Icon(
                  transfer.type == TransferType.upload ? Icons.upload_file : Icons.download,
                  color: _getStatusColor(transfer.status),
                ),
                title: Text(
                  transfer.fileName,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  transfer.type == TransferType.upload
                      ? 'Uploading to ${transfer.remotePath}'
                      : 'Downloading to ${transfer.localPath}',
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: isActive
                    ? IconButton(
                        icon: const Icon(Icons.cancel),
                        tooltip: 'Cancel transfer',
                        onPressed: () => ftpService.cancelTransfer(transferId),
                      )
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Remove from list',
                        onPressed: () => ftpService.removeTransfer(transferId),
                      ),
              ),
              
              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TransferProgressWidget(
                  stats: transfer,
                ),
              ),
              
              // Transfer details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status:'),
                        _buildStatusChip(transfer.status, transfer.errorMessage),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Transfer speed (for active transfers)
                    if (transfer.status == TransferStatus.inProgress) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Speed:'),
                          Text(transfer.currentSpeed.toStringAsFixed(2) + ' KB/s'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Time remaining (for active transfers)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Remaining:'),
        Text(
        TransferCalculator.formatElapsedTime(Duration(seconds:transfer.timeRemainingSeconds ?? 1))),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    // Start time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Started:'),
                        Text(
                          _formatDateTime(transfer.startTime),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // End time (for completed transfers)
                    if (transfer.status != TransferStatus.inProgress && transfer.endTime != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Completed:'),
                          Text(
                            _formatDateTime(transfer.endTime!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Empty state placeholder
  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sync, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Status chip with appropriate color
  Widget _buildStatusChip(TransferStatus status, String? errorMessage) {
    String label;
    Color color;
    
    switch (status) {
      case TransferStatus.queued:
        label = 'Not Started';
        color = Colors.grey;
        break;
      case TransferStatus.inProgress:
        label = 'In Progress';
        color = Colors.blue;
        break;
      case TransferStatus.completed:
        label = 'Completed';
        color = Colors.green;
        break;
      case TransferStatus.failed:
        label = errorMessage != null ? 'Failed' : 'Failed';
        color = Colors.red;
        break;
      case TransferStatus.cancelled:
        label = 'Cancelled';
        color = Colors.orange;
        break;
    }
    
    return Tooltip(
      message: errorMessage ?? label,
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        backgroundColor: color,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // Get status color
  Color _getStatusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.queued:
        return Colors.grey;
      case TransferStatus.inProgress:
        return Colors.blue;
      case TransferStatus.completed:
        return Colors.green;
      case TransferStatus.failed:
        return Colors.red;
      case TransferStatus.cancelled:
        return Colors.orange;
    }
  }

  // Format date time
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  // Confirm clearing all completed transfers
  void _confirmClearCompleted(FtpService ftpService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Completed Transfers'),
        content: const Text('Remove all completed transfers from the list?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Clear All'),
            onPressed: () {
              Navigator.of(context).pop();
              
              // Remove all completed transfers
              final completedTransferIds = ftpService.activeTransfers.where((e) => e.status != TransferStatus.inProgress)
                  .map((e) => e.id)
                  .toList();
              
              for (final id in completedTransferIds) {
                ftpService.removeTransfer(id);
              }
            },
          ),
        ],
      ),
    );
  }

  String _printDuration(Duration duration) {
    String negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
