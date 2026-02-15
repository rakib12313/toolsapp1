import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../widgets/responsive/responsive_builder.dart';

/// Video Compressor Tool Screen
class VideoCompressorScreen extends StatefulWidget {
  const VideoCompressorScreen({super.key});

  @override
  State<VideoCompressorScreen> createState() => _VideoCompressorScreenState();
}

class _VideoCompressorScreenState extends State<VideoCompressorScreen> {
  File? _selectedVideo;
  int _quality = 75;
  
  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Compressor'),
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          if (_selectedVideo == null)
            _buildFilePickerCard()
          else ...[
            _buildVideoPreviewCard(),
            const SizedBox(height: 16),
            _buildQualityCard(),
            const SizedBox(height: 16),
            _buildActionButton(),
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
              'Compress Video',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Reduce video file size',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.folder_open),
              label: const Text('Pick Video'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVideoPreviewCard() {
    return Card.outlined(
      child: ListTile(
        leading: const Icon(Icons.video_file),
        title: Text(_selectedVideo!.path.split('/').last.split('\\').last),
        subtitle: Text('${(_selectedVideo!.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB'),
        trailing: TextButton(
          onPressed: _pickVideo,
          child: const Text('Change'),
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
            Text('Compression Quality: $_quality%', 
              style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _quality.toDouble(),
              min: 20,
              max: 100,
              divisions: 80,
              label: '$_quality%',
              onChanged: (value) => setState(() => _quality = value.toInt()),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton() {
    return FilledButton.icon(
      onPressed: _showFeatureDialog,
      icon: const Icon(Icons.compress),
      label: const Text('Compress Video'),
    );
  }
  
  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedVideo = File(result.files.single.path!));
    }
  }
  
  void _showFeatureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Note'),
        content: const Text(
          'Video compression requires FFmpeg/media processing libraries. '
          'This demo UI shows the interface design. Full implementation would use ffmpeg_kit_flutter package.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
