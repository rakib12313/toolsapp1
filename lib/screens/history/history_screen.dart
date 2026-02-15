import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/history_provider.dart';
import '../../models/history_item.dart';
import '../../widgets/responsive/responsive_builder.dart';
import 'package:intl/intl.dart';

/// History screen showing recent tool operations
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    final historyProvider = Provider.of<HistoryProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('History',
          style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (historyProvider.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear All',
              onPressed: () => _showClearHistoryDialog(context, historyProvider),
            ),
        ],
      ),
      body: historyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : historyProvider.items.isEmpty
              ? _buildEmptyState(context, horizontalPadding)
              : _buildHistoryList(context, historyProvider, horizontalPadding),
    );
  }
  
  Widget _buildHistoryList(BuildContext context, HistoryProvider provider, double padding) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
      itemCount: provider.items.length,
      itemBuilder: (context, index) {
        final item = provider.items[index];
        return _buildHistoryCard(context, item, provider);
      },
    );
  }
  
  Widget _buildHistoryCard(BuildContext context, HistoryItem item, HistoryProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(item.timestamp);
    
    return Card.outlined(
      margin: const EdgeInsets.bottom(12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.status == 'success' 
              ? colorScheme.primaryContainer.withOpacity(0.5)
              : colorScheme.errorContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item.status == 'success' ? Icons.check_circle_outline : Icons.error_outline,
            color: item.status == 'success' ? colorScheme.primary : colorScheme.error,
          ),
        ),
        title: Text(item.toolName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => provider.deleteEntry(item.id),
        ),
        onTap: () {
          _showHistoryDetails(context, item);
        },
      ),
    );
  }
  
  void _showHistoryDetails(BuildContext context, HistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.toolName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('File', item.fileName),
            _detailRow('Size', _formatFileSize(item.fileSize)),
            _detailRow('Status', item.status),
            if (item.outputPath != null) _detailRow('Saved to', item.outputPath!),
            if (item.errorMessage != null) _detailRow('Error', item.errorMessage!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showClearHistoryDialog(BuildContext context, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to delete all history items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context, double padding) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 24),
            Text('No History Yet', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Your processed files will appear here', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
