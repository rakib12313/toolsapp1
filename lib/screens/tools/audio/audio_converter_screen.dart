import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../widgets/responsive/responsive_builder.dart';
import '../../../providers/history_provider.dart';
import '../../../models/history_item.dart';

/// Audio Converter Tool Screen
class AudioConverterScreen extends StatefulWidget {
  const AudioConverterScreen({super.key});

  @override
  State<AudioConverterScreen> createState() => _AudioConverterScreenState();
}

class _AudioConverterScreenState extends State<AudioConverterScreen> {
  File? _selectedAudio;
  String _outputFormat = 'mp3';
  int _bitrate = 192;
  
  final List<Map<String, String>> _formats = [
    {'value': 'mp3', 'label': 'MP3', 'icon': '🎵'},
    {'value': 'wav', 'label': 'WAV', 'icon': '🎼'},
    {'value': 'flac', 'label': 'FLAC', 'icon': '🎹'},
    {'value': 'm4a', 'label': 'M4A', 'icon': '🎶'},
    {'value': 'ogg', 'label': 'OGG', 'icon': '🎸'},
  ];
  
  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Converter'),
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          if (_selectedAudio == null)
            _buildFilePickerCard()
          else ...[
            _buildAudioPreviewCard(),
            const SizedBox(height: 16),
            _buildFormatCard(),
            const SizedBox(height: 16),
            _buildBitrateCard(),
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
              Icons.library_music,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Convert Audio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Convert audio files between formats',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickAudio,
              icon: const Icon(Icons.folder_open),
              label: const Text('Pick Audio'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAudioPreviewCard() {
    return Card.outlined(
      child: ListTile(
        leading: const Icon(Icons.audiotrack),
        title: Text(_selectedAudio!.path.split('/').last.split('\\').last),
        subtitle: Text(_formatFileSize(_selectedAudio!.lengthSync())),
        trailing: TextButton(
          onPressed: _pickAudio,
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
            Text('Output Format', style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
  
  Widget _buildBitrateCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bitrate: $_bitrate kbps', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            Slider(
              value: _bitrate.toDouble(),
              min: 64,
              max: 320,
              divisions: 8,
              label: '$_bitrate kbps',
              onChanged: (value) => setState(() => _bitrate = value.toInt()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('64 kbps', style: Theme.of(context).textTheme.bodySmall),
                Text('320 kbps', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _bitrate >= 256 ? 'High Quality' : _bitrate >= 128 ? 'Standard Quality' : 'Low Quality',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton() {
    return FilledButton.icon(
      onPressed: _showFeatureDialog,
      icon: const Icon(Icons.transform),
      label: const Text('Convert Audio'),
    );
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  
  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedAudio = File(result.files.single.path!));
    }
  }
  
  void _showFeatureDialog() async {
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    
    // Simulate recording history for the demo
    await historyProvider.addEntry(HistoryItem(
      toolName: 'Audio Converter',
      toolId: 'audio_converter',
      fileName: _selectedAudio!.path.split('/').last.split('\\').last,
      fileSize: _selectedAudio!.lengthSync(),
      status: 'success',
    ));
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Note'),
        content: const Text(
          'Audio conversion requires FFmpeg for codec support. '
          'This demo UI demonstrates the interface. Full implementation would use audio processing libraries like ffmpeg_kit_flutter or just_audio.\n\n'
          'History entry has been recorded for this operation.',
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
