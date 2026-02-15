import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
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
  File? _selectedImage;
  Uint8List? _imageBytes;
  Uint8List? _convertedImageBytes;
  bool _isProcessing = false;
  
  String _outputFormat = 'jpg';
  int _quality = 90;
  
  final List<Map<String, String>> _formats = [
    {'value': 'jpg', 'label': 'JPG', 'icon': '🖼️'},
    {'value': 'png', 'label': 'PNG', 'icon': '🎨'},
    {'value': 'webp', 'label': 'WebP', 'icon': '🌐'},
    {'Value': 'bmp', 'label': 'BMP', 'icon': '🎞️'},
  ];
  
  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Converter'),
        actions: [
          if (_convertedImageBytes != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareImage,
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          if (_selectedImage == null)
            _buildFilePickerCard()
          else
            _buildImagePreviewCard(),
          
          if (_selectedImage != null) ...[
            const SizedBox(height: 16),
            _buildFormatCard(),
            
            if (_outputFormat == 'jpg' || _outputFormat == 'webp') ...[
              const SizedBox(height: 16),
              _buildQualityCard(),
            ],
            
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
          
          if (_convertedImageBytes != null) ...[
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
              Icons.transform,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Select an Image',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose an image to convert',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.folder_open),
              label: const Text('Pick Image'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImagePreviewCard() {
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
                  'Selected Image',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.change_circle),
                  label: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.contain,
                  height: 200,
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
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _isProcessing ? null : _convertImage,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.transform),
            label: Text(_isProcessing ? 'Converting...' : 'Convert Image'),
          ),
        ),
        if (_convertedImageBytes != null) ...[
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: _saveImage,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ],
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
            Text(
              'Format: ${_outputFormat.toUpperCase()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Size: ${_formatFileSize(_convertedImageBytes!.length)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      
      setState(() {
        _selectedImage = file;
        _imageBytes = bytes;
        _convertedImageBytes = null;
      });
    }
  }
  
  Future<void> _convertImage() async {
    if (_imageBytes == null) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final result = await compute(_convertImageInIsolate, {
        'bytes': _imageBytes!,
        'format': _outputFormat,
        'quality': _quality,
      });
      
      setState(() {
        _convertedImageBytes = result;
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image converted successfully!')),
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
  
  static Uint8List _convertImageInIsolate(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final format = params['format'] as String;
    final quality = params['quality'] as int;
    
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    switch (format) {
      case 'jpg':
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
      case 'png':
        return Uint8List.fromList(img.encodePng(image));
      case 'webp':
        return Uint8List.fromList(img.encodeJpg(image, quality: quality)); // WebP not yet supported, using JPG
      case 'bmp':
        return Uint8List.fromList(img.encodeBmp(image));
      default:
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    }
  }
  
  Future<void> _saveImage() async {
    if (_convertedImageBytes == null) return;
    
    try {
      final storageProvider = Provider.of<StorageProvider>(context, listen: false);
      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
      
      final directoryPath = storageProvider.savePath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'converted_$timestamp.$_outputFormat';
      final filePath = '$directoryPath/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(_convertedImageBytes!);
      
      // Save to history
      await historyProvider.addEntry(HistoryItem(
        toolName: 'Image Converter',
        toolId: 'image_converter',
        fileName: fileName,
        fileSize: _convertedImageBytes!.length,
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
  
  Future<void> _shareImage() async {
    if (_convertedImageBytes == null) return;
    
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/converted_$timestamp.$_outputFormat';
      
      final file = File(filePath);
      await file.writeAsBytes(_convertedImageBytes!);
      
      await Share.shareXFiles([XFile(filePath)], text: 'Converted image');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }
}
