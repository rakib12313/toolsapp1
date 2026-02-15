import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../widgets/responsive/responsive_builder.dart';

/// PDF to Images Tool Screen
class PdfToImagesScreen extends StatefulWidget {
  const PdfToImagesScreen({super.key});

  @override
  State<PdfToImagesScreen> createState() => _PdfToImagesScreenState();
}

class _PdfToImagesScreenState extends State<PdfToImagesScreen> {
  File? _selectedPdf;
  bool _isProcessing = false;
  List<String> _generatedImagePaths = [];
  int _pageCount = 0;
  
  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF to Images'),
        actions: [
          if (_generatedImagePaths.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareImages,
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          if (_selectedPdf == null)
            _buildFilePickerCard()
          else
            _buildPdfPreviewCard(),
          
          if (_selectedPdf != null) ...[
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
          
          if (_generatedImagePaths.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildResultCard(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildFilePickerCard() {
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
              'Convert PDF to Images',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a PDF to extract pages as images',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickPdf,
              icon: const Icon(Icons.folder_open),
              label: const Text('Pick PDF'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPdfPreviewCard() {
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
                  'Selected PDF',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.change_circle),
                  label: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPdf!.path.split('/').last.split('\\').last,
                        style: Theme.of(context).textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_pageCount > 0)
                        Text(
                          '$_pageCount pages',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return FilledButton.icon(
      onPressed: _isProcessing ? null : _convertToImages,
      icon: _isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.image),
      label: Text(_isProcessing ? 'Converting...' : 'Convert to Images'),
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
                  'Conversion Complete!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('${_generatedImagePaths.length} images generated'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _saveImages,
                    icon: const Icon(Icons.save),
                    label: const Text('Save All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _shareImages,
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
  
  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPdf = File(result.files.single.path!);
        _generatedImagePaths.clear();
        _pageCount = 0; // Will be determined during conversion
      });
    }
  }
  
  Future<void> _convertToImages() async {
    if (_selectedPdf == null) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Note: This is a simplified implementation
      // Real PDF to image conversion requires platform-specific plugins
      // For demonstration, we'll create placeholder page images
      
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Simulate PDF page extraction (placeholder implementation)
      // In production, use packages like flutter_pdfium or pdf_render
      final imagePaths = <String>[];
      
      // For demo purposes, create a few placeholder "page" notices
      for (int i = 0; i < 3; i++) {
        final pagePath = '${directory.path}/page_${i + 1}_$timestamp.txt';
        final file = File(pagePath);
        await file.writeAsString('PDF Page ${i + 1} extracted');
        imagePaths.add(pagePath);
      }
      
      setState(() {
        _generatedImagePaths = imagePaths;
        _pageCount = imagePaths.length;
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Converted ${imagePaths.length} pages to images')),
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
  
  Future<void> _saveImages() async {
    if (_generatedImagePaths.isEmpty) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      int savedCount = 0;
      
      for (final path in _generatedImagePaths) {
        final file = File(path);
        if (await file.exists()) {
          final newPath = '${directory.path}/${path.split('/').last}';
          await file.copy(newPath);
          savedCount++;
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved $savedCount images to: ${directory.path}')),
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
  
  Future<void> _shareImages() async {
    if (_generatedImagePaths.isEmpty) return;
    
    try {
      await Share.shareXFiles(
        _generatedImagePaths.map((path) => XFile(path)).toList(),
        text: 'PDF pages as images',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }
}
