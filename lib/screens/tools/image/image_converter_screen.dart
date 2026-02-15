import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import '../../../core/utils/batch_processor_utils.dart';
import '../../../widgets/responsive/responsive_builder.dart';
import '../../../providers/storage_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../models/history_item.dart';

/// Image Converter Tool Screen
class ImageConverterScreen extends StatefulWidget {
  const ImageConverterScreen({super.key});

  @override
  State<ImageConverterScreen> createState() => _ImageConverterScreenState();
}

class _ImageConverterScreenState extends State<ImageConverterScreen> {
  final List<File> _selectedImages = [];
  final Map<String, Uint8List> _imageBytes = {};
  final Map<String, Uint8List> _convertedImageBytes = {};
  final Map<String, bool> _processingStatus = {};
  bool _isBatchProcessing = false;
  
  String _outputFormat = 'jpg';
  int _quality = 90;
  
  final List<Map<String, String>> _formats = [
    {'value': 'jpg', 'label': 'JPG', 'icon': '🖼️'},
    {'value': 'png', 'label': 'PNG', 'icon': '🎨'},
    {'value': 'webp', 'label': 'WebP', 'icon': '🌐'},
    {'value': 'bmp', 'label': 'BMP', 'icon': '🎞️'},
  ];
  
  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Converter'),
        actions: [
          if (_convertedImageBytes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareAllImages,
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          if (_selectedImages.isEmpty)
            _buildFilePickerCard()
          else ...[
            _buildImageList(),
            const SizedBox(height: 16),
            _buildFormatCard(),
            
            if (_outputFormat == 'jpg' || _outputFormat == 'webp') ...[
              const SizedBox(height: 16),
              _buildQualityCard(),
            ],
            
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 24),
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
              Icons.transform,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Select Images',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose images to convert (Batch support)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.folder_open),
              label: const Text('Pick Images'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageList() {
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
                  'Selected Images (${_selectedImages.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedImages.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final file = _selectedImages[index];
                final path = file.path;
                final isProcessing = _processingStatus[path] ?? false;
                final isDone = _convertedImageBytes.containsKey(path);
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _imageBytes.containsKey(path)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.memory(
                            _imageBytes[path]!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image, size: 48),
                  title: Text(
                    path.split(Platform.pathSeparator).last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    isDone
                        ? 'Converted'
                        : (isProcessing ? 'Converting...' : 'Pending'),
                    style: TextStyle(
                      color: isDone
                          ? Colors.green
                          : (isProcessing ? Colors.orange : null),
                      fontWeight: isDone || isProcessing ? FontWeight.bold : null,
                    ),
                  ),
                  trailing: isDone
                      ? IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () {
                             // Maybe show preview or share individual?
                          },
                        )
                      : (isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _removeImage(index),
                            )),
                );
              },
            ),
             if (_selectedImages.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Showing all images',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFormatCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Output Format',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _formats.map((format) {
                final isSelected = _outputFormat == format['value'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(format['icon']!),
                      const SizedBox(width: 8),
                      Text(format['label']!),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _outputFormat = format['value']!;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQualityCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quality',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Quality: $_quality%'),
              ],
            ),
            Slider(
              value: _quality.toDouble(),
              min: 10,
              max: 100,
              divisions: 90,
              label: '$_quality%',
              onChanged: (value) {
                setState(() {
                  _quality = value.toInt();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    final allDone = _selectedImages.isNotEmpty && 
                    _convertedImageBytes.length == _selectedImages.length;
                    
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _isBatchProcessing ? null : _convertAllImages,
            icon: _isBatchProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.transform),
            label: Text(_isBatchProcessing 
                ? 'Converting...' 
                : (allDone ? 'Convert Again' : 'Convert All')),
          ),
        ),
        if (_convertedImageBytes.isNotEmpty) ...[
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: _saveAllImages,
            icon: const Icon(Icons.save_alt),
            label: Text('Save All (${_convertedImageBytes.length})'),
          ),
        ],
      ],
    );
  }
  
  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    
    if (result != null) {
      for (var file in result.files) {
        if (file.path != null) {
          final f = File(file.path!);
          if (!_selectedImages.any((element) => element.path == f.path)) {
            _selectedImages.add(f);
            // Load bytes for preview
            f.readAsBytes().then((bytes) {
              if (mounted) {
                setState(() {
                  _imageBytes[f.path] = bytes;
                });
              }
            });
          }
        }
      }
      setState(() {});
    }
  }
  
  void _removeImage(int index) {
    setState(() {
      final file = _selectedImages[index];
      _imageBytes.remove(file.path);
      _convertedImageBytes.remove(file.path);
      _processingStatus.remove(file.path);
      _selectedImages.removeAt(index);
    });
  }
  
  Future<void> _convertAllImages() async {
    if (_selectedImages.isEmpty) return;
    
    setState(() {
      _isBatchProcessing = true;
      _convertedImageBytes.clear();
    });
    
    try {
      for (var file in _selectedImages) {
        setState(() {
          _processingStatus[file.path] = true;
        });
        
        final bytes = _imageBytes[file.path] ?? await file.readAsBytes();
        
        // Ensure bytes are loaded
        if (!_imageBytes.containsKey(file.path)) {
            _imageBytes[file.path] = bytes;
        }
        
        final result = await compute(_convertImageInIsolate, {
          'bytes': bytes,
          'format': _outputFormat,
          'quality': _quality,
        });
        
        if (mounted) {
          setState(() {
            _convertedImageBytes[file.path] = result;
            _processingStatus[file.path] = false;
          });
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Converted ${_selectedImages.length} images successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBatchProcessing = false;
        });
      }
    }
  }
  
  static Uint8List _convertImageInIsolate(Map<String, dynamic> params) {
    return BatchProcessorUtils.convertImage(
      params['bytes'] as Uint8List,
      params['format'] as String,
      params['quality'] as int,
    );
  }
  
  Future<void> _saveAllImages() async {
    if (_convertedImageBytes.isEmpty) return;
    
    try {
      final storageProvider = Provider.of<StorageProvider>(context, listen: false);
      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
      final directoryPath = storageProvider.savePath;
      
      int successCount = 0;
      
      for (var entry in _convertedImageBytes.entries) {
        final originalPath = entry.key;
        final bytes = entry.value;
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final originalName = originalPath.split(Platform.pathSeparator).last.split('.').first;
        final fileName = '${originalName}_converted_$timestamp.$_outputFormat';
        final filePath = '$directoryPath/$fileName';
        
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        // Save to history
        await historyProvider.addEntry(HistoryItem(
          toolName: 'Image Converter',
          toolId: 'image_converter',
          fileName: fileName,
          fileSize: bytes.length,
          outputPath: filePath,
          status: 'success',
        ));
        
        successCount++;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved $successCount images to: $directoryPath')),
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
  
  Future<void> _shareAllImages() async {
    if (_convertedImageBytes.isEmpty) return;
    
    try {
      final directory = await getTemporaryDirectory();
      final List<XFile> xFiles = [];
      
      for (var entry in _convertedImageBytes.entries) {
        final originalPath = entry.key;
        final bytes = entry.value;
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final originalName = originalPath.split(Platform.pathSeparator).last.split('.').first;
        final filePath = '${directory.path}/${originalName}_converted_$timestamp.$_outputFormat';
        
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        xFiles.add(XFile(filePath));
      }
      
      await Share.shareXFiles(xFiles, text: 'Converted images');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }
}
