import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../widgets/responsive/responsive_builder.dart';

/// Video Trimmer Tool Screen
class VideoTrimmerScreen extends StatefulWidget {
  const VideoTrimmerScreen({super.key});

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
  File? _selectedVideo;
  RangeValues _trimRange = const RangeValues(0, 100);
  
  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Trimmer'),
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          if (_selectedVideo == null)
            _buildFilePickerCard()
          else ...[
            _buildVideoPreviewCard(),
            const SizedBox(height: 16),
            _buildTrimCard(),
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
              Icons.content_cut,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Trim Video',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Cut and trim video clips',
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
        trailing: TextButton(
          onPressed: _pickVideo,
          child: const Text('Change'),
        ),
      ),
    );
  }
  
  Widget _buildTrimCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trim Range', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Start: ${_trimRange.start.toInt()}% | End: ${_trimRange.end.toInt()}%'),
            RangeSlider(
              values: _trimRange,
              min: 0,
              max: 100,
              divisions: 100,
              labels: RangeLabels(
                '${_trimRange.start.toInt()}%',
                '${_trimRange.end.toInt()}%',
              ),
              onChanged: (values) => setState(() => _trimRange = values),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton() {
    return FilledButton.icon(
      onPressed: _showFeatureDialog,
      icon: const Icon(Icons.content_cut),
      label: const Text('Trim Video'),
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
          'Video trimming requires FFmpeg for precise frame-level editing. '
          'This demo UI shows the interface. Full implementation would use video processing packages.',
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
