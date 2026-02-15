import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../widgets/responsive/responsive_builder.dart';
import '../../../providers/storage_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../models/history_item.dart';

/// Image Compressor Tool Screen
class ImageCompressorScreen extends StatefulWidget {
  const ImageCompressorScreen({super.key});

  @override
  State<ImageCompressorScreen> createState() => _ImageCompressorScreenState();
}

class _ImageCompressorScreenState extends State<ImageCompressorScreen> {
  File? _selectedImage;
  Uint8List? _imageBytes;
  Uint8List? _compressedImageBytes;
  bool _isProcessing = false;
  
  int _quality = 85;
  int? _originalSize;
  int? _compressedSize;
  
  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Compressor'),
        actions: [
          if (_compressedImageBytes != null)
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
            _buildQualityCard(),
            
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
          
          if (_compressedImageBytes != null) ...[
            const SizedBox(height: 24),
            _buildComparisonCard(),
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
              Icons.compress,
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
              'Choose an image to compress',
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
            const SizedBox(height: 12),
            if (_originalSize != null)
              Text(
                'Original size: ${_formatFileSize(_originalSize!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
              'Compression Quality',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Quality: $_quality%'),
                Text(
                  _getQualityLabel(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
            Text(
              'Lower quality = smaller file size',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
            onPressed: _isProcessing ? null : _compressImage,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.compress),
            label: Text(_isProcessing ? 'Compressing...' : 'Compress Image'),
          ),
        ),
        if (_compressedImageBytes != null) ...[
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
  
  Widget _buildComparisonCard() {
    final compressionRatio = _originalSize != null && _compressedSize != null
        ? ((1 - _compressedSize! / _originalSize!) * 100).toStringAsFixed(1)
        : '0';
    
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
                  'Compression Complete!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSizeCard(
                    'Original',
                    _formatFileSize(_originalSize ?? 0),
                    false,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildSizeCard(
                    'Compressed',
                    _formatFileSize(_compressedSize ?? 0),
                    true,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.savings,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Saved $compressionRatio% space!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSizeCard(String label, String size, bool isCompressed) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompressed
            ? Theme.of(context).colorScheme .secondaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            size,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getQualityLabel() {
    if (_quality >= 90) return 'Excellent';
    if (_quality >= 70) return 'Good';
    if (_quality >= 50) return 'Medium';
    return 'Low';
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
        _compressedImageBytes = null;
        _originalSize = bytes.length;
        _compressedSize = null;
      });
    }
  }
  
  Future<void> _compressImage() async {
    if (_imageBytes == null) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final result = await compute(_compressImageInIsolate, {
        'bytes': _imageBytes!,
        'quality': _quality,
      });
      
      setState(() {
        _compressedImageBytes = result;
        _compressedSize = result.length;
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image compressed successfully!')),
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
  
  static Uint8List _compressImageInIsolate(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final quality = params['quality'] as int;
    
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }
  
  Future<void> _saveImage() async {
    if (_compressedImageBytes == null) return;
    
    try {
      final storageProvider = Provider.of<StorageProvider>(context, listen: false);
      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
      
      final directoryPath = storageProvider.savePath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'compressed_$timestamp.jpg';
      final filePath = '$directoryPath/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(_compressedImageBytes!);
      
      // Save to history
      await historyProvider.addEntry(HistoryItem(
        toolName: 'Image Compressor',
        toolId: 'image_compressor',
        fileName: fileName,
        fileSize: _compressedImageBytes!.length,
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
    if (_compressedImageBytes == null) return;
    
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/compressed_$timestamp.jpg';
      
      final file = File(filePath);
      await file.writeAsBytes(_compressedImageBytes!);
      
      await Share.shareXFiles([XFile(filePath)], text: 'Compressed image');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }
}
