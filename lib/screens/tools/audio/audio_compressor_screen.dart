import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../widgets/responsive/responsive_builder.dart';
import '../../../providers/history_provider.dart';
import '../../../models/history_item.dart';

/// Audio Compressor Tool Screen
class AudioCompressorScreen extends StatefulWidget {
  const AudioCompressorScreen({super.key});

  @override
  State<AudioCompressorScreen> createState() => _AudioCompressorScreenState();
}

class _AudioCompressorScreenState extends State<AudioCompressorScreen> {
  File? _selectedAudio;
  double _compressionLevel = 50;
  int _bitrate = 128;
  
  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Compressor'),
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          if (_selectedAudio == null)
            _buildFilePickerCard()
          else ...[
            _buildAudioPreviewCard(),
            const SizedBox(height: 16),
            _buildCompressionCard(),
            const SizedBox(height: 16),
            _buildBitrateCard(),
            const SizedBox(height: 16),
            _buildEstimateCard(),
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
              Icons.graphic_eq,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Compress Audio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Reduce audio file size',
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
    final fileSize = _selectedAudio!.lengthSync();
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.audiotrack,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedAudio!.path.split('/').last.split('\\').last,
                        style: Theme.of(context).textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Original: ${_formatFileSize(fileSize)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _pickAudio,
                  child: const Text('Change'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompressionCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compression Level', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 16),
            Slider(
              value: _compressionLevel,
              min: 0,
              max: 100,
              divisions: 10,
              label: '${_compressionLevel.toInt()}%',
              onChanged: (value) {
                setState(() {
                  _compressionLevel = value;
                  // Adjust bitrate based on compression
                  _bitrate = (320 - (value * 2.5)).toInt();
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Low', style: Theme.of(context).textTheme.bodySmall),
                Text('Medium', style: Theme.of(context).textTheme.bodySmall),
                Text('High', style: Theme.of(context).textTheme.bodySmall),
              ],
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
            Text('Target Bitrate', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [64, 96, 128, 192, 256, 320].map((br) {
                return ChoiceChip(
                  label: Text('$br kbps'),
                  selected: _bitrate == br,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _bitrate = br;
                        _compressionLevel = ((320 - br) / 2.5);
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
  
  Widget _buildEstimateCard() {
    final originalSize = _selectedAudio!.lengthSync();
    final estimatedSize = (originalSize * (1 - _compressionLevel / 100)).toInt();
    final savedSize = originalSize - estimatedSize;
    final savedPercent = (_compressionLevel).toInt();
    
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Estimated Results', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Estimated Size:', style: Theme.of(context).textTheme.bodyMedium),
                Text(_formatFileSize(estimatedSize), 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  )),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Space Saved:', style: Theme.of(context).textTheme.bodyMedium),
                Text('${_formatFileSize(savedSize)} (~$savedPercent%)', 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.tertiary,
                  )),
              ],
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
      label: const Text('Compress Audio'),
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
      toolName: 'Audio Compressor',
      toolId: 'audio_compressor',
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
          'Audio compression requires FFmpeg or similar audio processing libraries. '
          'This demo UI demonstrates the interface. Full implementation would include codec-based compression algorithms.\n\n'
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
