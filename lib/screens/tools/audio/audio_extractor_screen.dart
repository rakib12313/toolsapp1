import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../widgets/responsive/responsive_builder.dart';

/// Audio Extractor Tool Screen
class AudioExtractorScreen extends StatefulWidget {
  const AudioExtractorScreen({super.key});

  @override
  State<AudioExtractorScreen> createState() => _AudioExtractorScreenState();
}

class _AudioExtractorScreenState extends State<AudioExtractorScreen> {
  File? _selectedVideo;
  String _outputFormat = 'mp3';
  int _quality = 192;
  
  final List<Map<String, String>> _formats = [
    {'value': 'mp3', 'label': 'MP3', 'icon': '🎵'},
    {'value': 'm4a', 'label': 'M4A', 'icon': '🎶'},
    {'value': 'wav', 'label': 'WAV', 'icon': '🎼'},
    {'value': 'flac', 'label': 'FLAC', 'icon': '🎹'},
  ];
  
  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Extractor'),
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          if (_selectedVideo == null)
            _buildFilePickerCard()
          else ...[
            _buildVideoPreviewCard(),
            const SizedBox(height: 16),
            _buildFormatCard(),
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
              Icons.music_note,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Extract Audio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Extract audio track from video files',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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
        subtitle: const Text('Video file selected'),
        trailing: TextButton(
          onPressed: _pickVideo,
          child: const Text('Change'),
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
            Text('Audio Format', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _formats.map((format) {
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(format['icon']!),
                      const SizedBox(width: 8),
                      Text(format['label']!),
                    ],
                  ),
                  selected: _outputFormat == format['value'],
                  onSelected: (selected) {
                    if (selected) setState(() => _outputFormat = format['value']!);
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
            Text('Bitrate: $_quality kbps', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _quality.toDouble(),
              min: 64,
              max: 320,
              divisions: 8,
              label: '$_quality kbps',
              onChanged: (value) => setState(() => _quality = value.toInt()),
            ),
            Text(
              _quality >= 256 ? 'High Quality' : _quality >= 128 ? 'Standard Quality' : 'Low Quality',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton() {
    return FilledButton.icon(
      onPressed: _showFeatureDialog,
      icon: const Icon(Icons.music_note),
      label: const Text('Extract Audio'),
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
          'Audio extraction from video requires FFmpeg for codec support. '
          'This demo UI demonstrates the interface. Full implementation would use audio processing libraries.',
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
