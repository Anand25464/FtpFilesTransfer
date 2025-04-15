import 'package:flutter/material.dart';
import '../models/transfer_stats.dart';
import '../utils/file_size_formatter.dart';
import '../utils/transfer_speed_calculator.dart';

class TransferProgressWidget extends StatelessWidget {
  final TransferStats stats;
  final VoidCallback? onCancel;

  const TransferProgressWidget({
    Key? key,
    required this.stats,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stats.fileName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: stats.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${FileSizeFormatter.formatBytes(stats.bytesTransferred)} / ${FileSizeFormatter.formatBytes(stats.fileSize)}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  TransferSpeedCalculator.formatProgress(stats.progress),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Speed: ${TransferSpeedCalculator.formatSpeed(stats.currentSpeed)}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  'ETA: ${TransferSpeedCalculator.formatRemainingTime(stats.timeRemainingSeconds)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (stats.isInProgress && onCancel != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
            if (stats.isFailed && stats.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${stats.errorMessage}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;
    IconData icon;

    switch (stats.status) {
      case TransferStatus.completed:
        color = Colors.green;
        label = 'Completed';
        icon = Icons.check_circle;
        break;
      case TransferStatus.inProgress:
        color = Colors.blue;
        label = stats.type == TransferType.download ? 'Downloading' : 'Uploading';
        icon = stats.type == TransferType.download
            ? Icons.download_rounded
            : Icons.upload_rounded;
        break;
      case TransferStatus.failed:
        color = Colors.red;
        label = 'Failed';
        icon = Icons.error_outline;
        break;
      case TransferStatus.cancelled:
        color = Colors.orange;
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
      case TransferStatus.queued:
        color = Colors.grey;
        label = 'Queued';
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor() {
    switch (stats.status) {
      case TransferStatus.completed:
        return Colors.green;
      case TransferStatus.inProgress:
        return Colors.blue;
      case TransferStatus.failed:
        return Colors.red;
      case TransferStatus.cancelled:
        return Colors.orange;
      case TransferStatus.queued:
        return Colors.grey;
    }
  }
}