import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../widgets/responsive/responsive_builder.dart';
import '../../../providers/storage_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../models/history_item.dart';

/// Image Resizer Tool Screen
class ImageResizerScreen extends StatefulWidget {
  const ImageResizerScreen({super.key});

  @override
  State<ImageResizerScreen> createState() => _ImageResizerScreenState();
}

class _ImageResizerScreenState extends State<ImageResizerScreen> {
  File? _selectedImage;
  Uint8List? _imageBytes;
  Uint8List? _processedImageBytes;
  bool _isProcessing = false;
  
  // Resize options
  bool _resizeByPercentage = true;
  double _percentage = 100;
  int _width = 1000;
  int _height = 1000;
  bool _maintainAspectRatio = true;
  
  int? _originalWidth;
  int? _originalHeight;
  
  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Resizer'),
        actions: [
          if (_processedImageBytes != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareImage,
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          // File picker button
          if (_selectedImage == null)
            _buildFilePickerCard()
          else
            _buildImagePreviewCard(),
          
          if (_selectedImage != null) ...[
            const SizedBox(height: 16),
            _buildResizeOptionsCard(),
            
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
          
          if (_processedImageBytes != null) ...[
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
              Icons.photo_size_select_large,
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
              'Choose an image to resize',
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
            if (_originalWidth != null && _originalHeight != null)
              Text(
                'Original: ${_originalWidth}x$_originalHeight px',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResizeOptionsCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resize Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Resize method selector
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Percentage'),
                  icon: Icon(Icons.percent),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Dimensions'),
                  icon: Icon(Icons.straighten),
                ),
              ],
              selected: {_resizeByPercentage},
              onSelectionChanged: (Set<bool> selection) {
                setState(() {
                  _resizeByPercentage = selection.first;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            if (_resizeByPercentage)
              _buildPercentageSlider()
            else
              _buildDimensionInputs(),
            
            if (!_resizeByPercentage) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Maintain Aspect Ratio'),
                value: _maintainAspectRatio,
                onChanged: (value) {
                  setState(() {
                    _maintainAspectRatio = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPercentageSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Scale: ${_percentage.toInt()}%'),
            if (_originalWidth != null && _originalHeight != null)
              Text(
                '${(_originalWidth! * _percentage / 100).toInt()}x${(_originalHeight! * _percentage / 100).toInt()} px',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
        Slider(
          value: _percentage,
          min: 10,
          max: 200,
          divisions: 190,
          label: '${_percentage.toInt()}%',
          onChanged: (value) {
            setState(() {
              _percentage = value;
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildDimensionInputs() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Width',
              suffixText: 'px',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final w = int.tryParse(value);
              if (w != null) {
                setState(() {
                  _width = w;
                  if (_maintainAspectRatio && _originalWidth != null && _originalHeight != null) {
                    _height = (_originalHeight! * w / _originalWidth!).round();
                  }
                });
              }
            },
            controller: TextEditingController(text: _width.toString()),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Height',
              suffixText: 'px',
            ),
            keyboardType: TextInputType.number,
            enabled: !_maintainAspectRatio,
            onChanged: (value) {
              final h = int.tryParse(value);
              if (h != null) {
                setState(() {
                  _height = h;
                });
              }
            },
            controller: TextEditingController(text: _height.toString()),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _isProcessing ? null : _processImage,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high),
            label: Text(_isProcessing ? 'Processing...' : 'Resize Image'),
          ),
        ),
        if (_processedImageBytes != null) ...[
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
                  'Resize Complete!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                _processedImageBytes!,
                fit: BoxFit.contain,
                height: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      
      // Decode image to get dimensions
      final image = img.decodeImage(bytes);
      
      setState(() {
        _selectedImage = file;
        _imageBytes = bytes;
        _processedImageBytes = null;
        if (image != null) {
          _originalWidth = image.width;
          _originalHeight = image.height;
          _width = image.width;
          _height = image.height;
        }
      });
    }
  }
  
  Future<void> _processImage() async {
    if (_imageBytes == null) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final result = await compute(_resizeImageInIsolate, {
        'bytes': _imageBytes!,
        'byPercentage': _resizeByPercentage,
        'percentage': _percentage,
        'width': _width,
        'height': _height,
      });
      
      setState(() {
        _processedImageBytes = result;
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image resized successfully!')),
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
  
  static Uint8List _resizeImageInIsolate(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final byPercentage = params['byPercentage'] as bool;
    final percentage = params['percentage'] as double;
    final targetWidth = params['width'] as int;
    final targetHeight = params['height'] as int;
    
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    img.Image resized;
    
    if (byPercentage) {
      final newWidth = (image.width * percentage / 100).round();
      final newHeight = (image.height * percentage / 100).round();
      resized = img.copyResize(image, width: newWidth, height: newHeight);
    } else {
      resized = img.copyResize(image, width: targetWidth, height: targetHeight);
    }
    
    return Uint8List.fromList(img.encodeJpg(resized, quality: 95));
  }
  
  Future<void> _saveImage() async {
    if (_processedImageBytes == null) return;
    
    try {
      final storageProvider = Provider.of<StorageProvider>(context, listen: false);
      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
      
      final directoryPath = storageProvider.savePath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'resized_$timestamp.jpg';
      final filePath = '$directoryPath/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(_processedImageBytes!);
      
      // Save to history
      await historyProvider.addEntry(HistoryItem(
        toolName: 'Image Resizer',
        toolId: 'image_resizer',
        fileName: fileName,
        fileSize: _processedImageBytes!.length,
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
    if (_processedImageBytes == null) return;
    
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/resized_$timestamp.jpg';
      
      final file = File(filePath);
      await file.writeAsBytes(_processedImageBytes!);
      
      await Share.shareXFiles([XFile(filePath)], text: 'Resized image');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }
}
