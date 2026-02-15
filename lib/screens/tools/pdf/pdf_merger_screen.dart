import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../models/history_item.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/storage_provider.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/batch_processor_utils.dart';
import '../../../widgets/responsive/responsive_builder.dart';

/// PDF Merger Tool Screen
class PdfMergerScreen extends StatefulWidget {
  const PdfMergerScreen({super.key});

  @override
  State<PdfMergerScreen> createState() => _PdfMergerScreenState();
}

class _PdfMergerScreenState extends State<PdfMergerScreen> {
  final List<File> _selectedPdfs = [];
  bool _isProcessing = false;
  File? _mergedPdf;
  
  // Cache for page counts to avoid re-reading files constantly
  final Map<String, int> _pageCounts = {};

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Merger'),
        actions: [
          if (_mergedPdf != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePdf,
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          if (_selectedPdfs.isEmpty)
             _buildPickerCard()
          else ...[
             _buildPdfListCard(),
             const SizedBox(height: 16),
             _buildActionButtons(),
          ],

          if (_mergedPdf != null) ...[
            const SizedBox(height: 24),
            _buildResultCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildPickerCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Merge PDF Files',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select multiple PDF files to merge (Drag to reorder)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickPdfs,
              icon: const Icon(Icons.add),
              label: const Text('Pick PDFs'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfListCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected PDFs (${_selectedPdfs.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickPdfs,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedPdfs.isEmpty)
               const SizedBox.shrink()
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedPdfs.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = _selectedPdfs.removeAt(oldIndex);
                    _selectedPdfs.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final file = _selectedPdfs[index];
                  final path = file.path;
                  final pageCount = _pageCounts[path];
                  
                  return ListTile(
                    key: ValueKey(path),
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      path.split(Platform.pathSeparator).last,
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: pageCount != null 
                        ? Text('$pageCount pages • ${_formatFileSize(file.lengthSync())}') 
                        : const Text('Loading details...'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.drag_handle, color: Colors.grey),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() {
                              _selectedPdfs.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return FilledButton.icon(
      onPressed: _selectedPdfs.length < 2 || _isProcessing ? null : _mergePdfs,
      icon: _isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.merge),
      label: Text(_isProcessing ? 'Merging...' : 'Merge PDFs'),
    );
  }

  Widget _buildResultCard() {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'PDFs Merged Successfully!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _savePdf,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sharePdf,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      final newFiles = <File>[];
      for (var path in result.paths) {
        if (path != null) {
          final file = File(path);
          
          // Check file size (max 100MB)
          if (file.lengthSync() > 100 * 1024 * 1024) {
            if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Skipped ${path.split(Platform.pathSeparator).last}: File too large (>100MB)')),
               );
            }
            continue;
          }
          
          newFiles.add(file);
          
          // Get page count
          // We can do this in background to avoid jank
          // For now, doing it here or could use compute
          try {
             final PdfDocument doc = PdfDocument(inputBytes: file.readAsBytesSync());
             if (mounted) {
               setState(() {
                 _pageCounts[path] = doc.pages.count;
               });
             }
             doc.dispose();
          } catch (e) {
             print('Error reading PDF: $e');
          }
        }
      }
      
      setState(() {
        _selectedPdfs.addAll(newFiles);
      });
    }
  }

  Future<void> _mergePdfs() async {
    if (_selectedPdfs.length < 2) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final mergedBytes = await compute(_mergePdfsTask, _selectedPdfs.map((e) => e.path).toList());

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/merged_$timestamp.pdf';

      final file = File(filePath);
      await file.writeAsBytes(mergedBytes);

      setState(() {
        _mergedPdf = file;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDFs merged successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  static List<int> _mergePdfsTask(List<String> paths) {
      final List<Uint8List> pdfDataList = paths.map((path) => File(path).readAsBytesSync()).toList();
      return BatchProcessorUtils.mergePdfs(pdfDataList);
  }

  Future<void> _savePdf() async {
    if (_mergedPdf == null) return;

    try {
      final storageProvider = Provider.of<StorageProvider>(context, listen: false);
      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);

      final directoryPath = storageProvider.savePath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'merged_$timestamp.pdf';
      final filePath = '$directoryPath/$fileName';

      await _mergedPdf!.copy(filePath);

      // Save to history
      await historyProvider.addEntry(HistoryItem(
        toolName: 'PDF Merger',
        toolId: 'pdf_merger',
        fileName: fileName,
        fileSize: _mergedPdf!.lengthSync(),
        outputPath: filePath,
        status: 'success',
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_mergedPdf == null) return;

    try {
      await Share.shareXFiles([XFile(_mergedPdf!.path)], text: 'Merged PDF');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
